#!/bin/bash
set -e
#set -x

CONFIG=$1
SETUPTOOLS=`curl -s https://raw.githubusercontent.com/eea/eea.plonebuildout.core/master/buildout-configs/versions.cfg | grep "setuptools\s*\=\s*" | sed 's/ *//g' | sed 's/=//g' | sed 's/[a-z]//g'`
ZCBUILDOUT=`curl -s https://raw.githubusercontent.com/eea/eea.plonebuildout.core/master/buildout-configs/versions.cfg | grep "zc\.buildout\s*=\s*" | sed 's/^.*\=\s*//g'`
BOOSTRAP='https://raw.githubusercontent.com/eea/eea.plonebuildout.core/master/bootstrap.py'

if [ -z "$CONFIG" ]; then
  if [ -s "development.cfg" ]; then
    CONFIG="development.cfg"
  else
    CONFIG="buildout.cfg"
  fi
fi

echo ""
echo "Using $CONFIG"
echo ""

if [ -z "$SETUPTOOLS" ]; then
  SETUPTOOLS="7.0"
fi

echo "Using setuptools $SETUPTOOLS"
echo ""

if [ -z "$ZCBUILDOUT" ]; then
  ZCBUILDOUT="2.2.1"
fi

echo "Using zc.buildout $ZCBUILDOUT"
echo ""

if [ -z "$PYTHON" ]; then
  PYTHON="/usr/bin/env python2.7"
fi

# Make sure python is 2.7 or later
PYTHON_OK=`$PYTHON -c 'import sys
print (sys.version_info >= (2, 7) and "1" or "0")'`

if [ "$PYTHON_OK" = '0' ]; then
    echo "Python 2.7 or later is required"
    echo "EXAMPLE: PYTHON=/path/to/python2.7 ./install.sh"
    exit 0
fi

echo "Using Python: "
echo `$PYTHON --version`

echo "Adding eggs directory"
mkdir -p eggs

if [ -s "bin/activate" ]; then

  echo ""
  echo "Already a virtualenv environment."
  echo "Please remove bin/activate if you want to reinitiate it."
  echo ""

else

  echo "Installing virtualenv"
  # NOTE: virtualenv now doesn't download anything by default, so we need to provide setuptools
  curl -o "setuptools-$SETUPTOOLS.tar.gz" -k "https://pypi.python.org/packages/source/s/setuptools/setuptools-$SETUPTOOLS.tar.gz"
  curl -o "/tmp/virtualenv.py" -k "https://raw.githubusercontent.com/eea/virtualenv/1.10.X/virtualenv.py"
  # BBB update virtualenv
  #curl -o "/tmp/virtualenv.py" -k "https://raw.githubusercontent.com/pypa/virtualenv/13.1.0/virtualenv.py"

  echo "Running: $PYTHON /tmp/virtualenv.py --clear ."
  $PYTHON "/tmp/virtualenv.py" --clear .
  rm /tmp/virtualenv.py*
  rm "setuptools-$SETUPTOOLS.tar.gz"

fi

if [ ! -s "bootstrap.py" ]; then
  curl -o "bootstrap.py" -k $BOOSTRAP
fi

echo "Running bin/python bootstrap.py -c $CONFIG -v $ZCBUILDOUT --setuptools-version=$SETUPTOOLS"
bin/python "bootstrap.py" -c $CONFIG -v $ZCBUILDOUT --setuptools-version=$SETUPTOOLS

echo "Disabling the SSL CERTIFICATION for git"
git config --global http.sslVerify false

echo ""
echo "========================================================================="
echo "All set. Now you can run ./bin/buildout -c $CONFIG"
echo "========================================================================="
echo ""
