# Obtener la lista de módulos cargados
loaded_modules=$(lsmod | awk '{print $1}' | tail -n +2)

# Obtener la lista de módulos disponibles
available_modules=$(find /lib/modules/$(uname -r)/kernel -type f -name '*.ko*' | xargs -n 1 basename | sed 's/.ko.*//')

# Comparar las dos listas y encontrar los módulos disponibles pero no cargados
for module in $available_modules; do
    if ! echo "$loaded_modules" | grep -qw "$module"; then
        echo "$module"
    fi
done
