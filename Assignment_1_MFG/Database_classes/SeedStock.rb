#!/usr/bin/env ruby
# This assignment was made in collaboration with Ana Karina Ballesteros Gómez, Mariam El Akal Chaji and Ángela Gómez Sacristán.

class Seed
    # We define the attributes.
    attr_accessor :stock
    attr_accessor :mtgid
    attr_accessor :dataplanted
    attr_accessor :storage
    attr_accessor :gramsremain
  
    # We create variables to contain the database, header os the file and the hash (dictionary created with stock id and mutant gene ID).
    @@SeedDatabase = {}
    @@headers = {}
    @@seed_id = {}
    

    # We set the initial values for the Seeds Object
    def initialize (thisstock, thismtgid, thisdataplanted, thisstorage, thisgramsremain) 
  
        @stock = thisstock
        @mtgid = thismtgid
        @dataplanted = thisdataplanted
        @storage = thisstorage
        @gramsremain = thisgramsremain
        @@seed_id[stock] = thismtgid #creating a hash
    end
    

    # Function to read the file and save information into database variable.
    def self.reading_file (filename)
      file = CSV.read(filename, headers: true, col_sep: "\t")
      @@headers = file.headers
      i = 0
      file.each do |row|
        @@SeedDatabase[i] = Seed.new(row[0], row[1], row[2], row[3], row[4])
        i = i+1
      end 
      return @@SeedDatabase
    end
  
    def self.describe(seed)
      puts seed.stock
      puts seed.mtgid
      puts seed.dataplanted
      puts seed.storage
      puts seed.gramsremain
    end
    
    # We  generated the dictionary with the seed stock and the mutant gene id.
    def self.update_hash(data) #create hash
      @@seed_id.each do |data|
        data[1]
      end
    end 

    # Function that simulate the plantation of 7 grams of seeds of each stock
    # It actualices the stock info and gives a warning error if we finish the stock.
    def self.plantation ()
      (0..4).each do |n|
        numer_seeds = @@SeedDatabase[n].gramsremain.to_i
        if numer_seeds > 7
          @@SeedDatabase[n].gramsremain = numer_seeds - 7
          @@SeedDatabase[n].dataplanted = DateTime.now.strftime('%-d/%-m/%Y')
        elsif numer_seeds <= 7
          @@SeedDatabase[n].gramsremain = 0
          @@SeedDatabase[n].dataplanted = DateTime.now.strftime('%-d/%-m/%Y')
          puts ("WARNING!! We have run out of Seed Stock #{@@SeedDatabase[n].stock}")
        end
        
      end
  end
    

    #Function that creates file with given name which contains the seed stock data updated after the plantation.
    def self.gen_new_table(new_file_name)
      File.open("#{new_file_name}", "w") { |f| f.write "" }
      @@headers.each do |header|
        File.open("#{new_file_name}", "a") { |f| f.write "#{header}\t" }
      end
      File.open("#{new_file_name}", "a") { |f| f.write "\n" }
      (0..4).each do |n|
        File.open("#{new_file_name}", "a") { |f| f.write "#{@@SeedDatabase[n].stock}\t#{@@SeedDatabase[n].mtgid}\t#{@@SeedDatabase[n].dataplanted}\t#{@@SeedDatabase[n].storage}\t#{@@SeedDatabase[n].gramsremain}\n" }      
      end
    end


    # Function taht finds  seed information by typing its ID
    def self.find_seed_by_stock_id(id) #Find gene by ID
            @@SeedDatabase.each do |seedstock|
                if seedstock[1].stock == id
                  return seedstock[1]
                end
            end
      end
  
  end
