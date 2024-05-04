import yt_dlp

from flask import Flask, request
from youtubesearchpython import VideosSearch

app = Flask(__name__)


def search_videos(query, pages=1):
    """
    Given a keyword / query this function will return youtube video results against those keywords / query
    """

    videosSearch = VideosSearch(query, limit=50)
    wdata = videosSearch.result()["result"]
    for i in range(pages - 1):
        videosSearch.next()
        wdata.extend(videosSearch.result()["result"])
    return wdata


def getbitrate(x):
    """Return the bitrate of a stream."""
    return x.get("bitrate", -1)


def get_video_streams(ytid):
    """
    given a youtube video id returns different video / audio stream formats' \
    """

    with yt_dlp.YoutubeDL() as ydl:
        info_dict = ydl.extract_info(ytid, download=False)
        return [i for i in info_dict["formats"] if i.get("format_note") != "storyboard"]


@app.route("/search")
def search():
    query = request.args.get("query")
    wdata = search_videos(query)
    return wdata


@app.route("/get")
def get():
    video_id = request.args.get("id")
    streams = get_video_streams(video_id)
    streams = [x for x in streams if "audio" in x["resolution"]]
    streams = sorted(streams, key=getbitrate, reverse=True)

    if streams:
        url = streams[0]["url"]
        return url


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, threaded=True)
