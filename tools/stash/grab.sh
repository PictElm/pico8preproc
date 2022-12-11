#!/bin/sh -e
cd "`dirname $0`/../.cache"

test -f pico8_versions.csv || wget -O pico8_versions.csv https://gist.githubusercontent.com/PictElm/9e1930781b8c541f7199059ccc08cf89/raw/8780d7459ee7efa18ab5c769d1da52598233d362/pico8_versions.csv
test -d versions || mkdir versions

( here=`pwd`/version

  for ver in `tail -n+2 ../pico8_versions.csv | cut -d, -f1`
    do
      test 0.0.1 = $ver && continue

      if mkdir $ver 2>/dev/null
        then
          ( echo = querying binary for $ver >&2
            set -x
            cd $ver
            if wget https://www.lexaloffle.com/dl/7tiann/pico-8_${ver}_amd64.zip -O dl.zip
              then unzip dl.zip -d bin
              else test 8 -eq $? && continue
            fi
          )
      fi

      ( echo = proceeding with cached $ver >&2
        bin=bin/pico-8/pico8
        set -x
        cd $ver
        $bin -root_path `realpath $here/playground` -run some_file.p8
        printf waiting...
        read
      )

      echo = done with $ver >&2
  done
)
