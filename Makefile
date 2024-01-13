clean_data:
	rm -r .data/*

load_database:
	ruby benchmark/load_database.rb
