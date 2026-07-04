FROM python:3.12-slim AS base

WORKDIR mkdocs

COPY requirements.txt theme.yml ./

RUN pip install --no-cache-dir -r requirements.txt && \
  mkdir meridian-docs && cd meridian-docs && \
  mkdocs new .

#.
#├── docs
#│   └── index.md
#└── mkdocs.yml

# can move to alpine upon checking if everything is working as expected
FROM nginx

WORKDIR meridian
COPY --from=base mkdocs/meridian-docs/  ./usr/share/nginx/html

EXPOSE 8101
