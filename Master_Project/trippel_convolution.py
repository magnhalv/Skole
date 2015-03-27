from random import randint

write_file = open("conv_output.txt", "w")

def print_table(table_name, table):
	write_file.write(table_name + ":\n")
	for row in table:
		write_file.write(str(row) + " - " + str([col*2**8 for col in row]) + "\n")
	write_file.write("-\n")

def print_conv_table(table_name, tables):
	i = 0
	for table in tables:
		write_file.write(table_name + " " + str(i) + "\n")
		i = i + 1
		for row in table:
			write_file.write(str(row) + " - " + str([col*2**8 for col in row]) + "\n")
		write_file.write("-\n")

def convert_table(table):
	for row in table:
		r_string = ""
		for col in row:
 			if (col==0):
				r_string = r_string + "zero, "
			elif(col==1):
				r_string = r_string + "one, "
			elif(col==2):
				r_string = r_string + "two, "
			elif(col==3):
				r_string = r_string + "three, "
			elif(col==4):
				r_string = r_string + "four, "
			elif(col==5): 
				r_string = r_string + "five, "
		write_file.write(r_string + "\n")
	write_file.write("-\n")


n = 6
kernel_dim = 3
pool_dim = 2
nof_conv = 3
conv_range = n-kernel_dim+1
pooled_table_dim = conv_range/pool_dim

tables=[]

for j in range(0, nof_conv):
	tables.append([])
	for i in range(0, n):
		tables[j].append([(randint(-5, 5)) for x in range (0, n)])

kernel = []
for i in range(0, kernel_dim):
	kernel.append([(randint(-5,5)) for x in range(0, kernel_dim)])



conv_table=[]
for i in range(0, conv_range):
	conv_table.append([0 for x in range(0, conv_range)])

temp_conv_table=[]
for i in range(0, nof_conv):
	temp_conv_table.append([])
	for j in range(0, conv_range):
		temp_conv_table[i].append([0 for x in range(0, conv_range)])

for v in range(0, nof_conv):
	for i in range(0, conv_range):
		for j in range(0, conv_range):
			sum = 0
			for y in range(0, kernel_dim):
				for x in range(0, kernel_dim):
					sum = sum + tables[v][i+y][j+x]*kernel[y][x]
			conv_table[i][j]+=sum
			temp_conv_table[v][i][j] = sum
	



pl_table = []
for i in range(0, pooled_table_dim):
	pl_table.append([0 for x in range(0, pooled_table_dim)])

for i in range(0, pooled_table_dim):
	for j in range(0, pooled_table_dim):
		c_max = -1
		for y in range(0, pool_dim):
			for x in range(0, pool_dim):
				u = i*pool_dim+y
				v = j*pool_dim+x
				c_max = max(c_max, conv_table[u][v])
		pl_table[i][j]= c_max


print_conv_table("Input table", tables)
print_table("Kernel", kernel)
print_conv_table("Convolved table", temp_conv_table)
print_table("Sum of convolutions", conv_table)
print_table("Pooled table", pl_table)

write_file.write("Input tables converted: \n")
for table in tables:
	convert_table(table)

write_file.write("Converted kernel: ")
convert_table(kernel)
