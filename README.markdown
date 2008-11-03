Statig
======

Statig is a [thor](http://github.com/wycats/thor) task to manage a static website
tracked with git. Don't expect anything fancy.

Install
-------

    cd ~/web/example.org
    thor install http://github.com/sr/statig/statig.rb?raw=true
    cp statig.sample.yml config.yml
    echo "thor statig:build ." >> .git/hooks/post-commit

Usage
-----

    $EDITOR somepage.textile
    git commit -a -m "created somepage"

License
-------

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
                       Version 2, December 2004

    Copyright (C) 2008 Simon Rozet <simon@rozet.name>
    Everyone is permitted to copy and distribute verbatim or modified
    copies of this license document, and changing it is allowed as long
    as the name is changed.

               DO WHAT THE FUCK YOU WANT TO PUBLIC LICENSE
      TERMS AND CONDITIONS FOR COPYING, DISTRIBUTION AND MODIFICATION

     0. You just DO WHAT THE FUCK YOU WANT TO.
