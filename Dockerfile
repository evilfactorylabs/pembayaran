FROM ubuntu

ARG POSTGREST_VER=v7.0.1
ARG POSTGREST_CHECKSUM=05626b6e1f698fc40a6552bd5af657f2
ARG POSTGREST_ARCHIVE=postgrest-$POSTGREST_VER-linux-x64-static.tar.xz 

RUN apt-get update && apt-get install -y curl sqitch libdbd-pg-perl postgresql-client xz-utils

RUN curl -JOLs https://github.com/PostgREST/postgrest/releases/download/$POSTGREST_VER/$POSTGREST_ARCHIVE

RUN echo $POSTGREST_CHECKSUM $POSTGREST_ARCHIVE | md5sum -c

RUN tar -xvf $POSTGREST_ARCHIVE

RUN mv postgrest /usr/local/bin

RUN rm $POSTGREST_ARCHIVE

WORKDIR /app

COPY . .

EXPOSE 3000

CMD ["postgrest", "pembayaran.conf"]
