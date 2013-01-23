# heroku-manual-deploy

Manual deploy commands.

## Installation

```
$ heroku plugins:install git@github.com:heroku/heroku-manual-deploy.git
```

## Usage

```
# Deploy

$ heroku deploy web.1
Deploying web.1 process... done

$ heroku deploy web
Deploying web processes... done

$ heroku deploy
Deploying processes... done


# Rolling Deploy

$ heroku deploy:rolling web.1
Deploying web.1 process... done

$ heroku deploy:rolling web
Deploying web processes...
Deploying web.1 process... done
done

$ heroku deploy:rolling
Deploying processes...
Deploying web.1 process... done
done
```