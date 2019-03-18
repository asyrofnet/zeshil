# Building Documentation

There are 2 tools to build docs. First [MKDOCS](http://www.mkdocs.org/) to build static page via markdown file, second is [APIDOCJS](http://apidocjs.com/) to build Inline Documentation for RESTful web APIs.

Installing two of them is easy, but they need this prerequisites:

For MKDOCS, it needs:

* Python 2.7 or later
* PIP 1.5.2 or later

For APIDOCJS, needs:

* NodeJS v6 or later
* NPM v3 or later

Then install mkdocs and apidocjs:

```
$ sudo pip install mkdocs
$ sudo npm install --global apidoc
```

After installation completed, you can build new api doc using following command from rails root directory:

```
$ apidoc -i app/controllers -o docs/apidoc
```

Please keep in mind that you must generate apidoc in `docs/apidoc` directory.

If you change or add new file inside `docs/docs` directory (for instance you adding some note in there), you must re-generate your docs to html using mkdocs. First, change your directory to `docs`, then run `mkdocs build`, here is the full command:

```
$ cd docs
$ mkdocs build
$ cd ..
```

And now your documentation is up-to-date, don't forget to commit and push it into repo.