FROM python:3.12-slim AS base

WORKDIR /mkdocs

COPY ./docs/ requirements.txt theme.yml ./

RUN pip install --no-cache-dir -r requirements.txt && \
  mkdir meridian-docs && cd meridian-docs && \
  mkdocs new meridian && \
  cp -r ../docs/ meridian-docs/ && \
  mkdocs build # output to site/

#.
#├── docs
#│   └── index.md
#└── mkdocs.yml
# site/

# can move to alpine upon checking if everything is working as expected
FROM nginx

WORKDIR /meridian

COPY --from=base mkdocs/meridian-docs/site/  /usr/share/nginx/html/

EXPOSE 80
