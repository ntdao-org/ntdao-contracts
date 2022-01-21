FILE_CONTENTS="$(< $1 )"
node --experimental-repl-await -i -e "$FILE_CONTENTS"

