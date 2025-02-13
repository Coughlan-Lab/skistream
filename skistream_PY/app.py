import argparse
import asyncio
import json
import logging
import os
import ssl
import uuid
import sys

import socket

from aiohttp import web
from aiortc import MediaStreamTrack, RTCPeerConnection, RTCSessionDescription
import time
#from aiortc.contrib.media import MediaBlackhole, MediaPlayer, MediaRecorder, MediaRelay
#from av import VideoFrame

ROOT = os.path.dirname(__file__)

logger = logging.getLogger("pc")
pcs = set()
#relay = MediaRelay()

# find the local IP
s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
s.connect(("8.8.8.8", 80))
localIP = s.getsockname()[0]
s.close()

#async def index(request):
#    content = open(os.path.join(ROOT, "index.html"), "r").read()
#    return web.Response(content_type="text/html", text=content)


#async def javascript(request):
#    content = open(os.path.join(ROOT, "client.js"), "r").read()
#    return web.Response(content_type="application/javascript", text=content)

async def synch_get(request):
    return web.Response(
        content_type="application/json",
        text=json.dumps({"server_time": time.time()}),
    )


async def offer(request):
    params = await request.json()
    offer = RTCSessionDescription(sdp=params["sdp"], type=params["type"])

    pc = RTCPeerConnection()
    pc_id = "PeerConnection(%s)" % uuid.uuid4()
    pcs.add(pc)

    def log_info(msg, *args):
        logger.info(pc_id + " " + msg, *args)

    log_info("Created for %s", request.remote)

    # prepare local media
    #player = MediaPlayer(os.path.join(ROOT, "demo-instruct.wav"))
    #if args.record_to:
    #    recorder = MediaRecorder(args.record_to)
    #else:
    #    recorder = MediaBlackhole()

    @pc.on("datachannel")
    def on_datachannel(channel):
        @channel.on("message")
        def on_message(message):
            t = time.time()
            if isinstance(message, str) and message=="TR":
                #log_info("received on channel -> %s", message)
                channel.send(f"{t}")
            else:
                #log_info("class %s: %s", m, m.__class__)
                try:
                    m = message.decode("utf-8")
                    #json_m = json.loads(m)
                    #delay = t - float(json_m["sending_timestamp"])
                    #log_info("delay %s", delay)
                    #channel.send(f"{delay}")
                    log_info("received %s bytes", sys.getsizeof(message))
                    # Append the message and delay to a file
                    with open('messages_and_delays.txt', 'a') as file:
                        file.write(f"Message: {m}\n")
                    #log_info("received %s", message.__class__)
                    #log_info("received on channel -> %s", json_m)
                except Exception as e:
                    log_info("error: %s", e)
                    print(m)
                    
                
            
            
            #if isinstance(message, str):
            #    log_info("send back message")
            #    print(f"send back message")
            #    channel.send(f"pong {message[4:]}")

    @pc.on("connectionstatechange")
    async def on_connectionstatechange():
        log_info("Connection state is %s", pc.connectionState)
        if pc.connectionState == "failed":
            await pc.close()
            pcs.discard(pc)

    '''
    @pc.on("track")
    def on_track(track):
        log_info("Track %s received", track.kind)

        if track.kind == "audio":
            pc.addTrack(player.audio)
            recorder.addTrack(track)
        elif track.kind == "video":
            pc.addTrack(
                VideoTransformTrack(
                    relay.subscribe(track), transform=params["video_transform"]
                )
            )
            if args.record_to:
                recorder.addTrack(relay.subscribe(track))

        @track.on("ended")
        async def on_ended():
            log_info("Track %s ended", track.kind)
            await recorder.stop()
    '''

    # handle offer
    await pc.setRemoteDescription(offer)
    #await recorder.start()

    # send answer
    answer = await pc.createAnswer()
    await pc.setLocalDescription(answer)

    return web.Response(
        content_type="application/json",
        text=json.dumps(
            {"sdp": pc.localDescription.sdp, "type": pc.localDescription.type}
        ),
    )


async def on_shutdown(app):
    # close peer connections
    coros = [pc.close() for pc in pcs]
    await asyncio.gather(*coros)
    pcs.clear()


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="WebRTC audio / video / data-channels demo"
    )
    parser.add_argument("--cert-file", help="SSL certificate file (for HTTPS)")
    parser.add_argument("--key-file", help="SSL key file (for HTTPS)")
    parser.add_argument(
        "--host", default=localIP, help="Host for HTTP server (default: localIp)"
    )
    parser.add_argument(
        "--port", type=int, default=5000, help="Port for HTTP server (default: 5000)"
    )
    parser.add_argument("--record-to", help="Write received media to a file.")
    parser.add_argument("--verbose", "-v", action="count")
    args = parser.parse_args()


    if args.verbose:
        logging.basicConfig(level=logging.DEBUG)
    else:
        logging.basicConfig(level=logging.INFO)

    if args.cert_file:
        ssl_context = ssl.SSLContext()
        ssl_context.load_cert_chain(args.cert_file, args.key_file)
    else:
        ssl_context = None

    app = web.Application()
    app.on_shutdown.append(on_shutdown)
    #app.router.add_get("/", index)
    #app.router.add_get("/client.js", javascript)
    app.router.add_post("/offer", offer)
    app.router.add_get("/synch", synch_get)
    #print(f"server listen at {args.host}:{args.port}")
    web.run_app(
        app, access_log=None, host=args.host, port=args.port, ssl_context=ssl_context
    )
