# Node Dependencies

Check out-of-date dependencies for your Node.js app

## Example output

    $ node-dependencies --sort=urgency

    Package                   Local      Major      Minor      Patch
    tedious                   0.1.4        ---        ---      0.1.5
    mongoose                 3.6.11        ---        ---   3.6.0rc1
    optimist                  0.5.0        ---      0.6.0      0.5.2
    redis                     0.8.1        ---        ---      0.8.3
    underscore                1.4.3        ---        ---      1.4.4
    less-middleware          0.1.11        ---        ---     0.1.12
    express                   3.2.4        ---        ---      3.2.6
    grunt                     0.4.1        ---        ---   0.4.0rc8
    coffee-script             1.6.2        ---        ---      1.6.3
    bcrypt                    0.7.5        ---        ---      0.7.6
    knox                      0.8.2        ---        ---      0.8.3
    coffee-backtrace          0.2.0        ---      0.3.4      0.2.1
    socket.io                0.9.14        ---        ---    0.9.1-1
    async                    0.1.22        ---      0.2.9        ---
    mocha                     1.9.0        ---     1.11.0        ---
    less                      1.3.3        ---   1.4.0-b4        ---
    hbs                       2.1.0        ---      2.3.0        ---
    grunt-ember-handleba      0.4.0        ---      0.6.0        ---
    js-yaml                   1.0.3      2.1.0        ---        ---
    ent                       0.0.5        ---        ---        ---
    date-utils               1.2.13        ---        ---        ---
    jquery                    1.8.3        ---        ---        ---

## Installation

    sudo npm install -g node-dependencies

## Usage

    cd path/to/project
    node-dependencies

## Options

* `--sort`: Sort with either `alpha` or `urgency`
* `--homepage`: Print the homepage url with each library
