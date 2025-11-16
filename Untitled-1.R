rio <- read.csv("C:/Users/HP/Downloads/rio2016.csv")
View(rio)

#Question 9
upfstatistics <- c("Lorenzo Capello", "Alberto Santini", "Alessandro Ciancetta")

upf_olympians <- for (name in upfstatistics) {
if (name %in% rio) {
  print("yay olympian")
} else {
  print("well there's always 2028")
}
}

#Question 10
swim_count <- sum(rio$sport == "aquatics")
print(swim_count)

#Question 11
by_nation <- rio {
  distinct(id, .keep_all = TRUE)
  group_by(nationality) 
  summarise(count = n())
  arrange(desc(count))
}
print(by_nation)
