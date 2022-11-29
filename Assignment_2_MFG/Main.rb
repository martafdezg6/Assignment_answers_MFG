##Assignment2_BioinformaticRetos
#Colaborators: Ana Karina Ballesteros Gómez, Ángela Gómez Sacristán, Mariam El Akal Chaji, Marta Fernández González, Paula Fernández Aldama

require "csv"
require 'json'
require './InteractionNetwork.rb'

#Read Arabidopsis file
gene_list = InteractionNetwork.store_id_files(ARGV[0])

all_int = InteractionNetwork.get_nets_hash()
InteractionNetwork.fill_object(all_int)

InteractionNetwork.Show_report()