#!/bin/bash

echo "+++++++++++++++++++STARTING PIPELINES+++++++++++++++++++"

python3 /opt/tools/app.py
RET=$?

echo "+++++++++++++++++++END PIPELINES+++++++++++++++++++"

exit $RET
