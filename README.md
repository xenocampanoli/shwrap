shwrap
======

A shell command wrapping module, generally for use in programming many sequences of remote commands for a test framework like minitest.

Please see COPYRIGHT file, this directory, for copyright information.

Shwrap is a wrapper for shell commands to be executed over an ssh connection
(presumably keyed so no password is prompted for) so that objects can be
created in other frameworks, like Minitest, for remote testing of software, or
other remote running of software.  The idea is admittedly another flavor of
things others have done, (for instance Capistrano) and it is not necessarily
brilliantly original.  However, it does seem to get the job done, and the
reason I finished it now instead of doing other more interesting home projects
at this time is that I had a task at work with which I wanted to use minitest
to test remote installs of software.  So far it is exactly what I needed, and
I think the people I work with see it is clear, concise/minimalist, and easy to under- stand.  To try it, copy the shellx.rb to have your own name, presumably
a hostname you can get ssh keyed access to. Put together said keyed access,
reconfigure the objects in your copy of shellx, and then, presuming your shellx
copy is called yourshellxcopy.rb, do:

$ ruby user_test_shell_cmds.rb yourshellxcopy >myoutputfile.out

..on something like an Ubuntu system with a recent version of Ruby (Not 1.8.2).

So far I only provide one major working minitest battery with the Shwrap.rb
file of ruby classes, along with some stuff that is leftover from the
development process.  I'll try to get some other examples later.

Shwrap was conceived as a part of a larger framework idea, which I hope to
later also complete.  The framework is basically a set of very open, accessible
tools, in Ruby and other languages (like elixir, I hope), for doing common jobs
seen in development and software maintenance projects.  I got a very small part
of this framework done, and it may at best see the same fate as Donald Knuth's
famous unfinished work.  We'll see.
