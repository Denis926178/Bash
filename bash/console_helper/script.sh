#!/bin/bash

if [ $EUID -eq 0 ]; then
    echo "Запрещается запускать скрипт суперпользователем"
    exit
fi

# Вывод меню
menu(){
    echo "Спиок расширений временных файлов: $list_extensions_temp_files"
    echo "Список расширений рабочих файлов: $list_extensions_work_files"
    echo "Команда: $command"
    echo "Рабочая директория: $working_dir"
    echo "Директория конфига: $config_dir"
    echo """1) Посмотреть список расширений временных файлов
2) Задать заново список расширений временных файлов
3) Добавить расширение в список расширений временных файлов
4) Удалить расширение из списка временных файлов
5) Посмотреть список расширений рабочих файлов
6) Задать заново список расширений рабочих файлов
7) Добавить расширение в список расширений рабочих файлов
8) Удалить расширение из списка рабочих файлов
9) Посмотреть рабочую папку скрипта
10) Задать заново рабочую папку скрипта
11) Удалить временный файл
12) Посмотреть записанную команду
13) Выполнить записанную команду
14) Изменить записанную команду
15) Анализ целых чисел в рабочих файлах
16) Посмотреть объем каждого временного файла"""
}

# ======== функции работающие в тихом и обычном режиме ========

# Функция для проверки существования файла в текущей директории
check_extension(){
    if echo $1 | grep -Eq "^\.[[:alnum:]][[:alnum:]]*$"; then
        return 0
    fi
    return 1
}

# функция для обновления переменных в файле
setting_values(){
    echo -n "list_extensions_temp_files=\"$1\"
list_extensions_work_files=\"$2\"
working_dir=\"$3\"
command=\"$4\"
config_dir=\"$5\"" > "$config_dir"
}

# Создаем конфиг с настройками по умолчанию (В случае, если файл отсутствует, он будет создан автоматически)
setting_default_config(){
    config_dir="$(pwd)/settings.myconfig"
    working_dir=$(pwd)
    setting_values ".log" ".c" "$(pwd)" "grep error* program.c>last.log" "$(pwd)/settings.myconfig"
}

if [ ! -f settings.myconfig ]; then
    touch settings.myconfig
    setting_default_config
fi


# Обновление конфига
update_config(){
    setting_values "$list_extensions_temp_files" "$list_extensions_work_files" "$working_dir" "$command" "$config_dir"
}

# Функция для просмотра списка расширений
print_list_files(){
    echo "Список расширений временных файлов: $1"
}

# Функция для просмотра рабочей папки скрипта
print_work_dir_script(){
    echo "Рабочая папка скрипта: $working_dir"
}

# Функция для выполнения записанной команды
complete_command(){
    if eval $1 2>/dev/null; then
        echo "Команда успешно выполнена!"
    else   
        echo "Невозможно выполнить команду. Во время выполнения возникли ошибки."
    fi
}

# Функция для просмотра команды
print_command(){
    echo "Команда: $1"
}

# Вывод объема временных файлов 
print_volume_temp_files(){
    for mask in $1; do
        du -h *$mask 2>/dev/null
    done
}

# ======== /// функции работающие в тихом и обычном режиме /// ========

# ======== функции для обычного режима ========

# Функция для обновления списка расширений 
update_list_files(){
    echo "Вводите расширения в виде: .расширение"
    read -p "Введите новый список расширений: " start_extensions
    new_extensions=""
    start_extensions=$(echo $start_extensions | xargs -n1 | sort -u | xargs | sed "s# # #g")
    for extension in $start_extensions; do
        if check_extension "$extension"; then
            new_extensions="$new_extensions $extension"
        fi
    done
}

# Функция для добавления расширения в список расширений
add_extension_files(){
    echo "Введите расширение в виде: .расширение"
    read -p "Введите расширение, которое вы хотите добавить: " extension
    if ! check_extension "$extension"; then
        printf "Некорректный ввод расширения!"
    fi
    new_extensions="$1 $extension"
    new_extensions=$(echo $new_extensions | xargs -n1 | sort -u | xargs | sed "s# # #g")
}

# Функция для удаления расширения из списка расширений
delete_extension_files(){
    read -p "Введите номер расширения, которое вы хотите удалить: " number

    if ! echo $number | grep -Eq "^[1-9][0-9]*$"; then
        echo "Некорректно введен номер расширения!"
        return
    fi
    is_number="false"
    count=1
    new_extensions=""
    for extension in $1; do
        if [ $number -ne $count ]; then
            new_extensions="$new_extensions $extension"
        else
            is_number="true"
        fi
        count=$(($count+1))
    done
    if [ is_number = "false" ]; then
        echo "Расширения с таким номером в списке нет!"
    fi
}

# Функция для изменения рабочей папки скрипта
change_work_dir_script(){
    read -p "Введите новый путь до рабочей папки (можно ввести относительный или абсолютный путь): " new_working_dir
    if eval cd $new_working_dir 2>/dev/null; then
        return
    else
        echo "Некорректно введен новый путь до рабочей папки!"
    fi
}

# Функция для удаления временных файлов
delete_temp_files(){
    read -p "Введите название временного файла, который нужно удалить: " name
    flag="false"
    for i in $1; do
        if ! echo $name | grep -Eq "*$1"; then
            flag="false"
        else
            flag="true"
            break
        fi
    done
    if [ flag = "false" ]; then
        echo "Файла с таким именем не найдено!"
    else
        rm $name
    fi 
}

# Функция для изменения записанной команды
change_command(){
    read -p "Введите новую команду: " new_command
}

# Функция для анализа целых чисел в рабочих файлах
print_int_numbers(){
    for mask in $1; do 
        files=$(ls *$mask)
        for file in $files; do
            positions=($(grep -EoinH [-+]?[0-9]+ $file))
            numbers=($(grep -Eoih [-+]?[0-9]+ $file))
            for index in ${!numbers[@]}; do
                number=${numbers[$index]}
                position=${positions[$index]}
                if [ $number -ge -32000 -a $number -le 32000 2>/dev/null ]; then
                    printf "%-30s%-10s\n" $position "shorti"
                elif [ $number -ge -2000000000 -a $number -le 2000000000 2>/dev/null ]; then
                    printf "%-30s%-10s\n" $position "regi"
                fi
            done
        done
    done
}

# ======== /// функции для обычного режима /// ========

# ======== Функции для тихого режима ========

# Обновление списка расширений файлов (тихий режим)
update_list_files_s(){
    new_extensions=""
    for extension in $@; do
        new_extensions="$new_extensions $extension"
    done
    new_extensions=$(echo $new_extensions | xargs -n1 | sort -u | xargs | sed "s# # #g")
}
# Фунция для изменения рабочей директории (тихий режим)
change_work_dir_script_s(){
    if eval cd $3 2>/dev/null; then
        return
    else
        echo "Некорректно введен новый путь до рабочей папки!"
    fi
}
# Добавление новго расширения (тихий режим)
add_extension_files_s(){
    new_extensions="$1 $2"
    new_extensions=$(echo $new_extensions | xargs -n1 | sort -u | xargs | sed "s# # #g")
    echo $new_extensions
}

# Удаление файла из списка расширений (тихий режим)
delete_temp_files_s(){
    flag="false"
    for i in $1; do
        if ! echo $2 | grep -Eq "*$i"; then
            flag="false"
        else
            flag="true"
            break
        fi
    done
    if [ flag = "false" ]; then
        echo "Файла с таким именем не найдено!"
    else
        rm $2
    fi 
}

# Удаление элемента из списка расширений (тихий режим)
delete_extension_files_s(){
    count=1
    flag="false"
    new_extensions=""
    for extension in $1; do
        if [ $count -ne $2 ]; then
            new_extensions="$new_extensions $extension"
        else
            flag="true"
        fi
    done
    if [ flag = "false" ]; then
        echo "Некорректно введен номер расширения!"
    fi
}

# Изменение команды (тихий режим)
change_command_s(){
    new_command=$2
}

. settings.myconfig

# Выполнение основного скрипта
if [ $1 = "-s" 2>/dev/null ]; then

    if [ $2 = 1 2>/dev/null ]; then
        print_list_files "$list_extensions_temp_files"
    elif [ $2 = 2 2>/dev/null ]; then
        shift
        shift
        update_list_files_s "$@"
        list_extensions_temp_files=$new_extensions
    elif [ $2 = 3 2>/dev/null ]; then
        add_extension_files_s "$list_extensions_temp_files" "$3"
        list_extensions_temp_files=$new_extensions
    elif [ $2 = 4 2>/dev/null ]; then
        delete_extensions_files_s "$list_extensions_temp_files" "$3"
        list_extensions_temp_files=$new_extensions
    elif [ $2 = 5 2>/dev/null ]; then
        print_list_files "$list_extensions_work_files"
    elif [ $2 = 6 2>/dev/null ]; then
        update_list_files_s "$@"
        list_extensions_work_files=$new_extensions
    elif [ $2 = 7 2>/dev/null ]; then
        add_extension_files_s "$list_extensions_work_files" "$3"
        list_extensions_work_files=$new_extensions
    elif [ $2 = 8 2>/dev/null ]; then
        delete_extension_files_s "$list_extensions_work_files" "$3"
        list_extensions_work_files=$new_extensions
    elif [ $2 = 9 2>/dev/null ]; then
        print_work_dir_script
    elif [ $2 = 10 2>/dev/null ]; then
        change_work_dir_script_s "$3"
        $working_dir=$new_working_dir
    elif [ $2 = 11 2>/dev/null ]; then
        delete_temp_files_s "$list_extensions_temp_files" "$3"
    elif [ $2 = 12 2>/dev/null ]; then
        print_command "$command"
    elif [ $2 = 13 2>/dev/null ]; then
        complete_command "$command"
    elif [ $2 = 14 2>/dev/null ]; then
        change_command_s "$command" "$3"
        command=$new_command
    elif [ $2 = 15 2>/dev/null ]; then
        print_int_numbers "$list_extensions_work_files"
    elif [ $2 = 16 2>/dev/null ]; then
        print_volume_temp_files "$list_extensions_temp_files"
    elif [ $2 = "x" 2>/dev/null ]; then
        exit
    else
        echo "Неверно введен второй параметр скрипта!"
    fi
    update_config
    exit
else

    menu
    while true; do
        read -p 'Введите номер функции: ' choice
        if [ $choice = 1 2>/dev/null ]; then                               
            print_list_files "$list_extensions_temp_files"
        elif [ $choice = 2 2>/dev/null ]; then                             
            update_list_files 
            list_extensions_temp_files=$new_extensions
        elif [ $choice = 3 2>/dev/null ]; then                               
            add_extension_files "$list_extensions_temp_files"
            list_extensions_temp_files=$new_extensions
        elif [ $choice = 4 2>/dev/null ]; then                               
            delete_extension_files "$list_extensions_temp_files"
            list_extensions_temp_files=$new_extensions
        elif [ $choice = 5 2>/dev/null ]; then                              
            print_list_files "$list_extensions_work_files"
        elif [ $choice = 6 2>/dev/null ]; then                                
            update_list_files
            list_extensions_work_files=$new_extensions
        elif [ $choice = 7 2>/dev/null ]; then                               
            add_extension_files "$list_extensions_work_files"
            list_extensions_work_files=$new_extensions
        elif [ $choice = 8 2>/dev/null ]; then                              
            delete_extension_files "$list_extensions_temp_files"
            list_extensions_temp_files=$new_extensions
        elif [ $choice = 9 2>/dev/null ]; then                               
            print_work_dir_script
        elif [ $choice = 10 2>/dev/null ]; then
            change_work_dir_script
            $working_dir=$new_working_dir
        elif [ $choice = 11 2>/dev/null ]; then
            delete_temp_files
        elif [ $choice = 12 2>/dev/null ]; then
            print_command "$command"
        elif [ $choice = 13 2>/dev/null ]; then
            complete_command "$command"
        elif [ $choice = 14 2>/dev/null ]; then
            change_command "$command"
            command=$new_command
        elif [ $choice = 15 2>/dev/null ]; then
            print_int_numbers "$list_extensions_work_files"
        elif [ $choice = 16 2>/dev/null ]; then
            print_volume_temp_files "$list_extensions_temp_files"
        elif [ $choice = "x" 2>/dev/null ]; then
            exit
        else
            echo 'Некорректно введен номер функции!'
        fi
        update_config
    done
fi