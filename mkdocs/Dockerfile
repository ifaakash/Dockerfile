FROM python

WORKDIR mkdocs

COPY requirements.txt theme.yml ./

RUN pip install --no-cache-dir -r requirements.txt && \
  mkdir meridian-docs && cd meridian-docs && \
  mkdocs new .

#.
#├── docs
#│   └── index.md
#└── mkdocs.yml

