# TVBoxOSC

[![Build](https://img.shields.io/github/actions/workflow/status/zyqfork/TVBoxOSC/build-tvbox.yml?branch=master&logo=github&label=Build)](https://github.com/zyqfork/TVBoxOSC/actions/workflows/build-tvbox.yml)
[![Releases](https://img.shields.io/badge/Releases-Download-orange?logo=github)](https://github.com/zyqfork/TVBoxOSC/releases)
[![Downloads](https://img.shields.io/github/downloads/zyqfork/TVBoxOSC/total?color=yellow&logo=github&label=Downloads)](https://github.com/zyqfork/TVBoxOSC/releases)

Builds APKs from the projects below and publishes them as
[GitHub Releases](https://github.com/zyqfork/TVBoxOSC/releases). Releases are the
only place APKs are published.

Each target gets its own release, tagged `<owner>_<repo>_<branch>_<upstream commit date>`.
There is deliberately **no single "latest" release** — open the
[releases page](https://github.com/zyqfork/TVBoxOSC/releases) and pick the project you want.
A `SHA256SUMS` file accompanies every release (`sha256sum -c SHA256SUMS`).

## Credits

| Repository                                                  | Branch    | Last built commit                          | Build time          |
| ----------------------------------------------------------- | --------- | ------------------------------------------ | ------------------- |
| [q215613905/TVBoxOS](https://github.com/q215613905/TVBoxOS) | `main`    | `ab11d289e09963a9daf65ca7f6b7a9a8cbe184e1` | 2026-09-26 13:39:51 |
| [takagen99/Box](https://github.com/takagen99/Box)           | `main`    | `258a5fef61578869ae905ca230bdde9e99fc19a8` | 2026-09-26 13:52:22 |
| [zyqfork/TV](https://github.com/zyqfork/TV)                 | `release` | `6a3e2db3deb42b18980bea39e07b8daeb445e5c8` | 2026-09-26 13:57:39 |

`zyqfork/TV` is a source-buildable fork (ExoPlayer + MPV/FFmpeg); no FongMi
compatibility patch is applied to it.

_Last updated: 2026-09-26 13:57:39_
