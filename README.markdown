Statig
======

Statig is a [thor](http://github.com/wycats/thor) task to manage a static website
tracked with git. Don't expect anything fancy.

Install
-------

    cd ~/web/example.org
    thor install http://github.com/sr/statig/statig.rb?raw=true
    wget http://github.com/sr/statig/statig.sample.yml.rb?raw=true
    cp statig.sample.yml config.yml
    echo "thor statig:build ../.." >> .git/hooks/post-commit

Usage
-----

    $EDITOR somepage.textile
    git commit -a -m "some commit message"
