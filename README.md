## cspace-webapps-ucb
#### UCB Django webapp customizations

This Directory contains _sample_ configuration files for the various UCB tenants using the "Django webapps".

It also contains the code for custom apps for UCB tenants (i.e. apps that are not contributed to the core set, or were written specifically for a tenant).

Most of the config files will work with _production_ UCB deployments unmodified, but for use on Dev (or other) deployments
hostname, port, and other changes need to be made.

(For local development, you should make your own versions of most of these config files, and
see that they get copied to the appropriate directories after you have `configured` and `deployed` the apps using `setup.sh`.)

The files for the various UCB deployments here are designed to be deployed using
the "`setup.sh`" script in the `cspace-webapps-common` directory.  That script
merges the files here with the "vanilla" Django framework (in `cspace-webapps-common`) to create a
working Django project directory with suitable customizations.

As a generalization, the following files need to be present in the tenant directory for `setup.sh` to work properly.
* apps directory, containing the source code for any custom apps.
* config directory, containing the .cfg, .csv and other files required for each app.
* fixtures directory, containing any fixture content that needs to be deployed.
* `project_app.py`, a module containing the INSTALLED_APPS dictionary Django requires.
* `project_urls.py`, a module to be used as top-level `urls.py` for the project.

If you follow this pattern for your own custom apps and webapp configuration, you'll be able to use 
setup.sh as well, which may ease your maintenance and deployment efforts.

The contents of this repo only work when combined with the contents of the 'base repo'. See the README.md there for more details:

https://github.com/cspace-deployment/cspace-webapps-common

#### Updating the webapps 'splash page'

There is a static HTML "splash page" or "landing page" which is currently
installed on every webapp server (-prod, -qa, -dev) which
helps users navigate to the various webapps. (NB: the
webapps landing page at `TENANT/landing` provides the same info
for each tenant.)

The `listapp.py` script takes several possible parameters:
* `html` -- create the fancy HTML used on the splash page
* `table` -- create a tab-delimited app x tenant table of the webapps found
* `table-html` -- create plain html of the webapps table above
* `text` -- plaintext version of table, monospace font.

Also, you need to provide the 'deployment' (prod, dev, qa) as a second
parameter. (if no parameter is supplied, prod will be assumed)

For example, if the inventory of webapps on webapps-dev changes, the splash page can be updated, as follows:
```
(venv) app_webapps@blacklight-dev:$ cd ../cspace-webapps-ucb/
(venv) app_webapps@blacklight-dev:~/cspace-webapps-ucb$ python listapps.py html dev > /var/www/static/index.html
# edit the google tracking id to point to dev, if needed (i.e. -5 -> -6)
(venv) app_webapps@blacklight-dev:~/cspace-webapps-ucb$ vi /var/www/static/index.html
```

For Production:

```
(venv) app_webapps@blacklight-prod:$ cd ../cspace-webapps-ucb/
(venv) app_webapps@blacklight-prod:~/cspace-webapps-ucb$ python listapps.py html > /var/www/static/index.html
# no need to edit the google tracking id, it's already correct
```