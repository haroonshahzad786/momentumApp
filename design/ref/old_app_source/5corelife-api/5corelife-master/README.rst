api_momentum
============

API Momentum

.. image:: https://img.shields.io/badge/built%20with-Cookiecutter%20Django-ff69b4.svg
     :target: https://github.com/pydanny/cookiecutter-django/
     :alt: Built with Cookiecutter Django
.. image:: https://img.shields.io/badge/code%20style-black-000000.svg
     :target: https://github.com/ambv/black
     :alt: Black code style


Settings
--------

Moved to settings_.

.. _settings: http://cookiecutter-django.readthedocs.io/en/latest/settings.html


Installation
------------
Follow these steps carefully and sequentially.

1. Install some basics
 - Git
 - Docker

2. SSH Keys

  In order to clone this repo you will need:

 - Generate ssh keys if you don't have them yet. Simply ``ssh-keygen -t rsa``. It will generate your keys in ``/.ssh/id_rsa[.pub]``.
 - Set them up in your gitlab and github accounts.

3. Clone the 5corelife repo

    ``git clone https://gitlab.com/coderio/backend/5corelife.git``

4. Install python and configure environment

 - Install virtualenviroment click_here_
.. _click_here: https://packaging.python.org/en/latest/guides/installing-using-pip-and-virtual-environments/

 - Run the command to create virtual environment with a python version and install requirements/local.txt::

     make setup

Configure local environment
--------------------------

1. Copy and paste the following lines inside .zshrc or bashrc::

    envup() {
    if [ -f $1 ]; then
        export $(echo $(cat $1 | sed 's/#.*//g'| xargs) | envsubst)
    fi
    }

2. Reset zshrc or bashrc::

    source ~/.zshrc

    source ~/.bashrc

3. In this project we have a file named ``local.env``, run this command to set::

    envup local.env

4. Validate if the environment was set typing::

    export

5. Important, after when you run the command ``make start``, after this, you need to initialize data base whit data preloaded, you must run this command::

    make initialize-db

If this step is not run, you could create new users or create another information in the app.

Basic Commands
--------------

Build the project::

    make build

Run the project::

    make start

Create a superuser::

    make superuser

Initialize db::

    make initialize-db

Stop the project::

    make stop

Run tests::

    make test

Run coverage and generate file::

    make test-html

Check formatter, linter and tests::

    make all

Type checks
^^^^^^^^^^^

Running type checks with mypy:

::

  $ mypy api_momentum

Live reloading and Sass CSS compilation
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

Moved to `Live reloading and SASS compilation`_.

.. _`Live reloading and SASS compilation`: http://cookiecutter-django.readthedocs.io/en/latest/live-reloading-and-sass-compilation.html



Celery
^^^^^^

This app comes with Celery.

To run a celery worker:

.. code-block:: bash

    cd api_momentum
    celery -A config.celery_app worker -l info

Please note: For Celery's import magic to work, it is important *where* the celery commands are run. If you are in the same folder with *manage.py*, you should be right.

Sentry
^^^^^^

Sentry is an error logging aggregator service. You can sign up for a free account at  https://sentry.io/signup/?code=cookiecutter  or download and host it yourself.
The system is setup with reasonable defaults, including 404 logging and integration with the WSGI application.

You must set the DSN url in production.

Deployment
----------

The following details how to deploy this application.

Docker
^^^^^^

See detailed `cookiecutter-django Docker documentation`_.

.. _`cookiecutter-django Docker documentation`: http://cookiecutter-django.readthedocs.io/en/latest/deployment-with-docker.html


TODO
^^^^

- Create more test to up the coverage
- Fix formatter with black
- Fix linter
