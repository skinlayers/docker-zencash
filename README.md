# docker-zencash

## Build
```
docker build -t zencash:latest .
```

## Run
```
docker run \
    --init \
    -itd \
    --restart unless-stopped \
    --name zencash \
    -v zencash-data:/data \
    -p 8231:8231 \
    -p 9033:9033 \
    zencash:latest
```

## List Commands (From Host)
```
docker exec -it zencash zen-cli help
```

## List Commands (Inside Container)
```
docker exec -it zencash bash
zen-cli help
exit
```
