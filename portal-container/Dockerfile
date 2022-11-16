FROM ubuntu:22.04

ARG JOBS
ENV JOBS $JOBS
ARG USE_NICE
ENV USE_NICE $USE_NICE

RUN apt-get update && apt-get install -y \
  ffmpeg

WORKDIR /app

COPY ./video ./video/
COPY run.sh .
RUN chmod +x run.sh

CMD ./run.sh