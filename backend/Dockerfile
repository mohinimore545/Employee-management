# Stage 1: Build
FROM golang:1.19-alpine AS build
WORKDIR /app
COPY . .
RUN apk add --no-cache git
RUN go mod download
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o app .

# Stage 2: Minimal image
FROM alpine:latest
WORKDIR /root/
COPY --from=build /app/app .
ENV PORT=8080
EXPOSE 8080
CMD ["./app"]

