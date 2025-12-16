#Build Stage

FROM python:3.9-alpine AS build

WORKDIR /app

COPY . .

#Production Stage

FROM python:3.9-alpine AS builder

WORKDIR /app

COPY --from=build /app .

RUN addgroup -S app && adduser -S app -G app
USER app

EXPOSE 3000

CMD ["python", "-m", "http.server", "3000"]





