# Xyzzy

An [Interactive Fiction](https://en.wikipedia.org/wiki/Interactive_fiction) interpreter (Z-machine) in [Elixir](https://elixir-lang.org/).

I'm referencing the [Z-Machine Standards Document v1.1](http://inform-fiction.org/zmachine/standards/z1point1/) for the information on how the Z-machine works.

The goal is to eventually hook this up to [Slack](https://slack.com/) for some fun. That means leaving out support for games that require fancy graphics, timing, or sounds. So this will probably be restricted to the earlier Z-machine games only, like [Zork](https://en.wikipedia.org/wiki/Zork).


Getting Started
---------------

**Install the Elixir language, if you don't have it already:**

- [Windows](https://elixir-lang.org/install.html#windows)
- [Mac OS](https://elixir-lang.org/install.html#mac-os-x)
- [Linux](https://elixir-lang.org/install.html#unix-and-unix-like)


**Build the Xyzzy app:**

- Change to the directory where you cloned the Xyzzy repository and type:

 ```mix do deps.get, compile```


**Download some Z-machine games! Try some of these websites:**

- [INFOCOM Downloads](http://www.infocom-if.org/downloads/downloads.html)
- [IFDB](http://ifdb.tads.org/)


**Run Xyzzy with your adventure:**

- Again from the Xyzzy directory, type:

 ~~~
 iex -S mix
 Xyzzy.Machine.open_story("stories/zork_1.z3") |> Xyzzy.Machine.run_story()
 ~~~


Additional Resources
--------------------

- [What is Git?](https://en.wikipedia.org/wiki/Git)

- [How do I use Git?](https://git-scm.com/documentation)

- [Download GitHub Desktop for Windows or Mac](https://desktop.github.com/)

- [Download Git for Linux](https://git-scm.com/download/linux)

Xzzy was written by [David Phillips](https://github.com/daph). Licensed under the [BSD 3-Clause license](https://github.com/daph/xyzzy/blob/master/LICENSE). Feel free to submit [issues](https://github.com/daph/xyzzy/issues) and pull requests.
