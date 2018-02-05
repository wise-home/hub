# Changelog

## 0.4.1 - 2018-02-05

* Moved organization on Github, https://github.com/vesta-merkur/hub -> https://github.com/wise-home/hub


## 0.4.0 - 2017-12-18

* Can unsubscribe ([#8](https://github.com/wise-home/hub/pull/8))

Breaking changes:

* Hub.subscribe/3 and Hub.subscribe_quoted/3 now returns {:ok, reference} instead of :ok
* Attempting to subscribe with the same pattern again from the same pid on the same channel will now make two
  subscriptions. Before, the old one would be updated.

## 0.3.0 - 2017-11-22

* Can subscribe to multiple patterns in one subscription ([#6](https://github.com/wise-home/hub/pull/6))

## 0.2.1 - 2017-04-18

* Fix edge case pins

## 0.2.0 - 2017-04-18

* Allow local variables to be pinned in pattern ([#3](https://github.com/wise-home/hub/pull/3))

## 0.1.0 - 2017-04-14

First released version.

This was extracted from an existing private project.
