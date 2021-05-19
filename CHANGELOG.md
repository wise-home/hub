# Changelog

## 1.0.0 - 2021-05-19

Bumping to 1.0.0, since this has been used for years in production.

Added features:

* Added Hub.unsubscribe_and_flush, #178

Update dev deps:

* Update erlang 23.1.1 -> 24.0
* Update earmark_parser 1.4.10 -> 1.4.13
* Update ex_doc 0.23.0 -> 0.24.2
* Update elixir 1.11.0 -> 1.11.4
* Update dialyxir 1.0.0 -> 1.1.0
* Update credo 1.5.0-rc.4 -> 1.5.5
* Update makeup_elixir 0.15.0 -> 0.15.1
* Update file_system 0.2.9 -> 0.2.10, 144

## 0.6.6 - 2020-10-13

Nothing has changed in the code base, but we regularly update the development dependencies and versions of elixir and
erlang used for builds in CI.

Releasing new version to get docs out in the latest version of ex_doc

* Update erlang 21.3.6 -> 23.1.1
* Update elixir 1.8.1 -> 1.11.0, 130
* Remove support for elixir 1.9.4
* Update credo 1.0.5 -> 1.5.0-rc.4
* Update ex_doc 0.20.2 -> 0.23.0
* Update makeup_elixir 0.14.0 -> 0.15.0, 130
* Update makeup 1.0.0 -> 1.0.5, 130
* Update nimble_parsec 0.5.0 -> 1.1.0, 130
* Update jason 1.1.2 -> 1.2.2
* Update earmark 1.3.2 -> 1.4.9
* Update dialyxir 0.5.1 -> 1.0.0
* Update erlex 0.2.5 -> 0.2.6

## 0.6.5 - 2019-04-23

* Use ExDoc 0.20.2

## 0.6.4 - 2019-04-10

* Use new ExDoc 0.20.1

## 0.6.3 - 2019-04-03

* Use new ExDoc 0.20.0

## 0.6.2 - 2018-07-30

* Fixed warnings new to Elixir 1.7

## 0.6.1 - 2018-04-24

* Fixed race condition if two processes try to start the same channel at the same time by calling subscribe.

## 0.6.0 - 2018-04-24

* Now has no external dependencies. Removed Phoenix PubSub in favor of in-process state in `Channel`.

This is a somewhat backwards incompatible update:

* Since Phoenix PubSub is no longer used, it is no longer using CRDTs to sync state between nodes. However, Hub was
really not compatible with multiple nodes before anyway.
* The return type of `Hub.subscribe/3` and `Hub.subscribe_quoted/3` is now
`Channel.subscription_ref :: {pid, reference}` instead of `reference`. This is now also the type that `Hub.unsubscribe`
accepts. If the calling code don't require the return value to be a `reference` it will continue to work as before.

## 0.5.0 - 2018-04-20

* Runs every channel in its own process to avoid race condition

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
