#Assignment3_BioinformaticRetos
# @author Ana Karina Ballesteros Gómez, Ángela Gómez Sacristán, Mariam El Akal Chaji, Marta Fernández González, Paula Fernández Aldama

require 'csv'
require './GFF_functions.rb'

file = read_file()
#this stores all the gene ids of the list in an array

bioseq = search_CTTCCT(file) #aplying the search_CTTCCT function from the GFF_functions file

write_files(bioseq) #using the write_files function from GFF_functions to write the output final files. 