# Downloader for 1fichier.com using Tor
## Changes in this fork
- Added optional argument `Output-Path`, if not used the directory in which the executable is located is used.
- Added optional argument `--verbose`
- Added docker usage

## Description

Content in [Tor](https://www.torproject.org/) is often saved on hosters like [1fichier.com](https://1fichier.com/).

A user named SoupeAuLait from the board Rindexxx (no longer available) wrote a script to download files from 1fichier.com. The script changed the circuit of Tor until a "free slot" for 1fichier.com was found and downloaded the file.

I grabbed this script and rewrote most parts of it. My improvements are
- Improve readability (speaking variables, proper indentation, ...).
- Prefer local variables instead of global ones.
- Allowed mass downloading by putting all links into a text file.
- Skip already downloaded files.
- Verify downloaded files (very limited).
- Use temp folder for all temporary files.
- Remove temporary files after download.

## Usage

### Docker

1. Download the Docker dockerfile `wget https://raw.githubusercontent.com/Yemtex/1fichier-downloader/master/1fichier.dockerfile`
3. Build Docker image from dockerfile `docker build -t 1fichier -f 1fichier.dockerfile .`
4. Build Docker container from image `docker run -d --name 1fichier 1fichier:latest`
4. Open interactive TTY `docker exec -it 1fichier sh`
5. Run script like standalone script

### Standalone script

`./1fichier.sh File-With-URLs [Output-Path] [--verbose]`

or

`./1fichier.sh URL [Output-Path] [--verbose]`

## Contact

Author: eismann

Freemail: eismann@vu6osveg7rpxh2ckrh7ivdyilprn52px2gtxtp4bxjckn46oc6ia.freemail [^1]

Frost: eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs

FMS: eismann

Sone: [eismann](http://localhost:8888/Sone/viewSone.html?sone=rTzpVIb8X3PoSon~io8IW~Le6ffRp3m-gbpEpvPOF5A) [^2]

I do not regularly read the email associated with GitHub.

## License

1fichier.sh by eismann@5H+yXYkQHMnwtQDzJB8thVYAAIs is licensed under the [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0).

[^1]: Freemail requires a running Freenet node
[^2]: Link requires a running Freenet node at http://localhost:8888/
