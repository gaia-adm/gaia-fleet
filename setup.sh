#!/bin/sh

test_connection()
{
  wget -T 5 -s http://www.google.com >> /dev/null
}

test_proxy()
{
  # no array in Broune shell (default Alpine shell)
  while read line
  do
    set -- "$@" "$line"
  done

  # first try no proxy
  test_connection

  if [ $? -eq 0 ]; then
   echo "No proxy is necessary"
   return 0
  else
    echo "Detecting suitable proxy server.."
    for i do
      http_proxy=$i; export http_proxy
      https_proxy=$i; export https_proxy
      no_proxy=localhost,127.0.0.1; export no_proxy

      test_connection
      if [ $? -eq 0 ]; then
        echo "Connection through proxy '${http_proxy}' was successful"
        return 0
      fi
    done
  fi
  echo "No suitable proxy was found"
  return 1
}

# detect if proxy is needed
test_proxy

# setup proxy in Alpine Linux
touch /etc/profile.d/proxy.sh
if [ $http_proxy ]; then
  setup-proxy ${http_proxy}
fi
