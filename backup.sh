#!/usr/bin/env bash

# Directorios fuente para el backup.
src_dir=("/home/kali" "/home/guest" "/root/.bashrc" "/root/.ssh/")

# Directorio destino para guardar los backup.
tgt_dir="/home/kali/Backup"

# Exluir los ficheros que concuerden con el patrón.
exclude=("Backup/")
exclude+=("Downloads/" "mnt/" "tmp/")

# Eliminar backups anteriores a 2 meses.
age=$(date +%F --date='2 months ago')
for i in "$tgt_dir"/*
do
    if [[ -d $i ]] && [[ ${age//-} -ge $(echo "$i" | sed -r 's/^.*([0-9]{4})-([0-9]{2})-([0-9]{2})T.*$/\1\2\3/') ]] 2>/dev/null
    then
        rm -rf "$i"
    fi
done

# Generar una lista del array de input.
src_dir=$(printf -- '"%s" ' "${src_dir[@]}")

# Generamos una lista con el array de excluídos.
exclude=$(printf -- "--exclude '%s' " "${exclude[@]}")

# Crear el directorio de backup en caso de no existir.
[[ ! -d $tgt_dir ]] && mkdir -p "$tgt_dir"

# Directorio de backup actual, ej. "2020-12-05T05:02:40";
now=$(date +%FT%H:%M:%S)

# Directorio de backup previo.
prev=$(ls "$tgt_dir" | grep -e '^....-..-..T..:..:..$' | tail -1);

make_backup() {
    if [[ -z $prev ]]; then
        # Backup inicial.
        eval rsync -av --delete ${exclude} ${src_dir} "$tgt_dir/$now/"
    else
        # Backup incremental.
        eval rsync -av --delete --link-dest="$tgt_dir/$prev/" ${exclude} ${src_dir} "$tgt_dir/$now/"
    fi
}; make_backup > "${tgt_dir}/.backup.log" 2>&1

# Crea un log ocn unas estadísticas.
echo -e "\n${now}\t$(du -hs "$tgt_dir/$now")\n" >> "${tgt_dir}/.backup.log"
df -h "$tgt_dir" >> "${tgt_dir}/.backup.log"
exit 0;