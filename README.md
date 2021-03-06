# Liverpie 0.6

Liverpie is a Language Independent IVR Proxy. It stays between Freeswitch
and any web app, written in any language and running on any platform, that
functions as a state machine that describes an IVR (Interactive Voice
Response system).

There are many APIs and software products available that will help you write
an IVR using Freeswitch, but they all depend on a particular programming 
language and require that you either learn that language, or at least the
API itself.

With Liverpie, you can write your IVR in your favourite language, as a
regular web app, as long as it runs like a state machine (you keep calling
the same thing and it gives different replies each time, depending on a
predefined schema). You can code that in any way you like, and there are
a few examples on the site.

Liverpie will talk to your web app on one end, and to Freeswitch on the 
other -- that's what qualifies it as a proxy.

Read more at [http://www.liverpie.com].

## Requirements

* ruby (at least 1.8)

## Installation

1. Download from [https://github.com/alxx/Liverpie/archive/master.zip]
2. Expand the archive
3. Run `bundle install`

## Running

`bin/liverpie -h`

## Documentation

See [https://github.com/alxx/Liverpie]

## Support

Use GitHub, or there's an older Google Group at [http://groups.google.com/group/liverpie-support].

My email is alxx@indigenious.ro and I'm available for consultancy regarding the installation and usage of Liverpie.

## CREDITS

Jonathan Palley, author of Telegraph for FreeSWITCH, wrote the part that
instantiates an EventMachine and creates a server ready for FreeSWITCH.
I wrote everything else and changed some of Jonathan's code.

Adeel Ansari helped with the Java example and also worked with me to fix
a bug that prevented some Java webservers that don't always send a cookie
to work with Liverpie.


## LICENSE

##### The MIT License

Copyright (c) 2008 Alex Deva, parts of code written by Jonathan Palley

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
