(function () {
    const video = document.getElementById('video');
    const statusEl = document.getElementById('streamStatus');
    const WHEP_URL = '/webrtc/cam/whep';
    const HLS_URL = '/hls/cam/index.m3u8';
    let pc = null, hls = null, mode = 'webrtc', failures = 0, timer = null, stopped = false;

    function setStatus(live, text) {
        statusEl.textContent = text || (live ? 'Live' : 'Camera offline');
        statusEl.className = 'stream-status ' + (live ? 'live' : 'offline');
    }

    function retry() {
        if (stopped) return;
        clearTimeout(timer);
        failures++;
        setStatus(false);
        if (mode === 'webrtc' && failures >= 3 && (hlsSupported() || nativeHls())) {
            mode = 'hls';
        }
        const delay = Math.min(2000 * failures, 10000);
        timer = setTimeout(start, delay);
    }

    function cleanup() {
        if (pc) { pc.onconnectionstatechange = null; pc.close(); pc = null; }
        if (hls) { hls.destroy(); hls = null; }
        video.srcObject = null;
        video.removeAttribute('src');
    }

    function hlsSupported() { return window.Hls && Hls.isSupported(); }
    function nativeHls() { return video.canPlayType('application/vnd.apple.mpegurl') !== ''; }

    async function startWebRTC() {
        pc = new RTCPeerConnection({ iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] });
        const mine = pc;
        pc.addTransceiver('video', { direction: 'recvonly' });
        // MediaMTX's answer carries no stream id, so e.streams is empty: build our own.
        const stream = new MediaStream();
        pc.ontrack = (e) => {
            stream.addTrack(e.track);
            if (video.srcObject !== stream) video.srcObject = stream;
            video.play().catch(() => {});
        };
        pc.onconnectionstatechange = () => {
            if (mine !== pc) return;
            if (pc.connectionState === 'connected') { failures = 0; setStatus(true); video.play().catch(() => {}); }
            else if (['failed', 'disconnected', 'closed'].includes(pc.connectionState)) { cleanup(); retry(); }
        };
        await pc.setLocalDescription(await pc.createOffer());
        // Wait for ICE gathering so a single POST carries all candidates.
        await new Promise((res) => {
            if (pc.iceGatheringState === 'complete') return res();
            const t = setTimeout(res, 2000);
            pc.onicegatheringstatechange = () => {
                if (pc.iceGatheringState === 'complete') { clearTimeout(t); res(); }
            };
        });
        const resp = await fetch(WHEP_URL, {
            method: 'POST',
            headers: { 'Content-Type': 'application/sdp' },
            body: pc.localDescription.sdp,
            credentials: 'same-origin',
        });
        if (resp.status === 401) { location.href = '/login'; return; }
        if (!resp.ok) throw new Error('WHEP ' + resp.status);
        await mine.setRemoteDescription({ type: 'answer', sdp: await resp.text() });
    }

    function startHLS() {
        if (hlsSupported()) {
            hls = new Hls({ lowLatencyMode: true });
            const mine = hls;
            hls.loadSource(HLS_URL);
            hls.attachMedia(video);
            hls.on(Hls.Events.MANIFEST_PARSED, () => { failures = 0; setStatus(true); video.play().catch(() => {}); });
            hls.on(Hls.Events.ERROR, (_e, data) => {
                if (!data.fatal || mine !== hls) return;
                if (data.type === Hls.ErrorTypes.MEDIA_ERROR) { hls.recoverMediaError(); return; }
                cleanup(); retry();
            });
        } else {
            video.src = HLS_URL;
            video.onloadedmetadata = () => { failures = 0; setStatus(true); video.play().catch(() => {}); };
            video.onerror = () => { cleanup(); retry(); };
        }
    }

    async function start() {
        cleanup();
        setStatus(false, 'Connecting...');
        try {
            if (mode === 'webrtc' && window.RTCPeerConnection) await startWebRTC();
            else if (hlsSupported() || nativeHls()) { mode = 'hls'; startHLS(); }
            else { stopped = true; setStatus(false, 'Browser not supported'); }
        } catch (err) {
            cleanup(); retry();
        }
    }

    // Stalled HLS (stream dropped without error): treat as offline
    video.addEventListener('stalled', () => { if (mode === 'hls') setStatus(false, 'Buffering...'); });
    start();
})();
