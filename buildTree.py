import json
import os
import csv

current_order = 0
wallet_default = "0x0000000000000000000000000000000000000000"

def dfs(node, partner_order, partner_wallet, node_list, all_nodes, additional_data):
    """
    Recorrido en profundidad del árbol y recolección de datos.
    """
    global current_order
    # wallet default
    global wallet_default

    if not node:
        return
    
    
    
    # Incrementar el orden
    node_order = current_order
    current_order += 1

    wallet_left_child = wallet_default
    wallet_right_child = wallet_default
    left_child_order = ""
    right_child_order = ""

    # Extracción de USERNAME y FULL NAME
    username, full_name = extract_name_data(node['name'])

    # Buscar datos adicionales
    extra_data = additional_data.get(username, {})
    
    # Wallet del sponsor
    wallet_sponsor = node['attributes'].get('sponsors_wallet_address', wallet_default)

    wallet_address = node['attributes'].get('wallet_address', wallet_default)

    data = {
        "ORDER": node_order,
        "WALLET": wallet_address,
        "WALLET SPONSOR": wallet_sponsor,
        "WALLET PARTNER": partner_wallet,
        "WALLET LEFT CHILD": wallet_left_child,
        "WALLET RIGHT CHILD": wallet_right_child,
        "BALANCE": node['attributes'].get('donated', 0),
        "PARTNER ORDER": partner_order,
        "LEFT CHILD ORDER": left_child_order,
        "RIGHT CHILD ORDER": right_child_order,
        "USERNAME": username,
        "FULL NAME": full_name,
        "EMAIL": extra_data.get("EMAIL", ""),
        "ADDRESS": extra_data.get("ADDRESS", ""),
        "CITY": extra_data.get("CITY", ""),
        "STATE": extra_data.get("STATE", ""),
        "ZIP CODE": extra_data.get("ZIP CODE", ""),
        "DONATE CATEGORY": extra_data.get("DONATE CATEGORY", ""),
        "PHONE": extra_data.get("PHONE", ""),
        "COUNTRY": extra_data.get("COUNTRY", "")
    }

    wallet_address = node['attributes'].get('wallet_address', wallet_default)

    # Recursivamente procesar hijos
    if 'children' in node:
        if len(node['children']) > 0:
            wallet_left_child = node['children'][0]['attributes'].get('wallet_address', wallet_default)
            left_child_order = current_order  # Antes de llamar a dfs para el hijo izquierdo
            dfs(node['children'][0], node_order, wallet_address, node_list, all_nodes, additional_data)

        if len(node['children']) > 1:
            wallet_right_child = node['children'][1]['attributes'].get('wallet_address', wallet_default)
            right_child_order = current_order  # Antes de llamar a dfs para el hijo derecho
            dfs(node['children'][1], node_order, wallet_address, node_list, all_nodes, additional_data)

    data["WALLET LEFT CHILD"] = wallet_left_child
    data["WALLET RIGHT CHILD"] = wallet_right_child
    data["LEFT CHILD ORDER"] = left_child_order  # Añade el orden del hijo izquierdo a data
    data["RIGHT CHILD ORDER"] = right_child_order  # Añade el orden del hijo derecho a data
    node_list.append(data)

def extract_name_data(name):
    """
    Extrae el USERNAME y FULL NAME de la cadena name.
    """
    full_name = name.split('(')[0].strip()
    if '(' in name and ')' in name:
        # Obtiene el contenido dentro de los paréntesis
        inner_content = name.split('(')[1].split(')')[0]
        # Divide el contenido por espacios y toma solo el primer elemento
        username = inner_content.split()[0]
    else:
        username = ""
    
    return username, full_name

def write(tree, filename, additional_data):
    global current_order
    global wallet_default
    all_nodes = {}
    flatten_tree(tree, all_nodes)
    node_list = []
    dfs(tree, 0, wallet_default, node_list, all_nodes, additional_data)
    
    # Ordena node_list basado en la columna "ORDER"
    node_list = sorted(node_list, key=lambda x: x["ORDER"])

    with open(filename, 'w', newline='') as csvfile:
        fieldnames = ["ORDER", "WALLET", "WALLET SPONSOR", "WALLET PARTNER", "WALLET LEFT CHILD", "WALLET RIGHT CHILD", "BALANCE",
              "PARTNER ORDER", "LEFT CHILD ORDER", "RIGHT CHILD ORDER", "USERNAME", "FULL NAME", "EMAIL", "PHONE", "ADDRESS",
              "COUNTRY", "STATE", "CITY", "ZIP CODE", "DONATE CATEGORY"]
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for row in node_list:
            writer.writerow(row)
    current_order = 1
    write_json(node_list, "resource/output.json")

def write_json(node_list, filename):
    # Transforma las claves del diccionario a minúsculas y reemplaza espacios por "_"
    transformed_data = [
        {transform_key(k): v for k, v in node.items()}
        for node in node_list
    ]

    with open(filename, 'w') as jsonfile:
        json.dump(transformed_data, jsonfile, indent=4)

def transform_key(key):
    """Convierte la clave a minúsculas y reemplaza espacios por '_'."""
    return key.lower().replace(' ', '_')

def flatten_tree(node, all_nodes, order=0):
    """
    Crea un diccionario plano de todos los nodos para una búsqueda más rápida.
    """
    if not node:
        return

    all_nodes[order] = node
    
    # Verificar si 'children' existe en el nodo
    if 'children' in node:
        if len(node['children']) > 0:
            flatten_tree(node['children'][0], all_nodes, order*2 + 1)
        if len(node['children']) > 1:
            flatten_tree(node['children'][1], all_nodes, order*2 + 2)

def load_additional_data(filename):
    data = {}
    with open(filename, 'r') as csvfile:
        reader = csv.DictReader(csvfile)
        for row in reader:
            username = row['username']
            data[username] = {
                "EMAIL": row['email'],
                "ADDRESS": row['addressLine'],
                "CITY": row['city'],
                "STATE": row['region'],
                "ZIP CODE": row['zip'],
                "DONATE CATEGORY": row['donationCategory'].upper().replace(" ", "_"),
                "PHONE": row['phone'],
                "COUNTRY": row['country']
            }
    return data

if __name__ == "__main__":
# 1. Ejecutar el archivo TypeScript y generar el archivo JSON
    #os.system("cd resource && ts-node tree.ts && cd ..")

    # Leer el archivo JSON
    with open('resource/tree.json', 'r') as file:
        tree = json.load(file)

    # Leer el archivo CSV con datos adicionales
    additional_data = load_additional_data('resource/hj_tree.csv')

    # Por cada árbol en la lista de árboles, procesar y escribir en un archivo CSV
    write(tree, "resource/output.csv", additional_data)
    # for tree in trees:
