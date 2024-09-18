FROM alpine/ansible:2.17.0

MAINTAINER Chris Sim <csim.zw@gmail.com>

RUN apk update && apk add gettext git

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
