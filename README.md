![](media/logo.svg)

[![Build status](https://build.appcenter.ms/v0.1/apps/494bd498-b124-49e5-894e-2f093e06d45b/branches/master/badge)](https://install.appcenter.ms/orgs/quicktype/apps/quicktype-xcode/distribution_groups/Xcode%20Testers)
[![Join us in Slack](http://slack.quicktype.io/badge.svg)](http://slack.quicktype.io/)

`quicktype` infers types from sample JSON data, then outputs strongly typed models and serializers for working with that data in Swift, C++, Obj-C++, Java and more. This extension adds native `quicktype` support to Xcode 9.

Try `quicktype` in your browser at [app.quicktype.io](https://app.quicktype.io).

# Installation

1. [Download the extension](https://github.com/quicktype/quicktype-xcode/releases/download/v8.0.29/quicktype-xcode.zip)
1. Launch `quicktype.app`
1. Enable the extension in `System Preferences > Extensions`
1. Open Xcode and find the `Editor > Paste JSON as` menu

---

![paste json as code](media/demo.gif)

## Development

### Install prereqs and bundle quicktype

```bash
$ brew install jq
$ npm install
$ pod install
```
