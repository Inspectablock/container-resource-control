FROM ubuntu:22.04

ARG CPUS
ENV CPUS $CPUS

RUN apt-get update && apt-get install -y \
  stress-ng

WORKDIR /app

COPY run.sh .
RUN chmod +x run.sh

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

CMD ./run.sh