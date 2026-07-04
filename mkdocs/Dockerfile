FROM python:3.12-slim AS base

WORKDIR /mkdocs

COPY requirements.txt ./
COPY meridian/ ./

RUN pip install --no-cache-dir -r requirements.txt && \
  mkdocs build 

#.
#├── docs
#│   └── index.md
#└── mkdocs.yml
# site/

# can move to alpine upon checking if everything is working as expected
FROM nginx

COPY --from=base /mkdocs/site/  /usr/share/nginx/html/

EXPOSE 80
