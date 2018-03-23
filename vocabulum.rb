#! /usr/bin/env ruby

class Lima
  attr_reader :linguae, :vocabuli

  def initialize(dateiname)
    @dateiname = dateiname
    @linguae = []
    @vocabuli = []

    z = 0
    File.read(@dateiname).split("\n").each do |versus|
      versus.chomp! #Zeilenumbruch entfernen
      if z == 0
        @linguae = versus.split(";")[1..-2]
      else
        id = versus.split(";")[0].to_i
        verbi = versus.split(";")[1..-2]
        treffsicherheiten = versus.split(";")[-1].to_i
        @vocabuli << Vocabulum.new(id,@linguae,verbi,treffsicherheiten)
      end
      z += 1
    end
  end

  def speichere_neue_daten(verbi)
    system("cp #{@dateiname} #{@dateiname}.bak")
    csv = File.open(@dateiname, "w") 
    csv.write(";" + @linguae.join(";") + ";Treffsicherheit\n")
    verbi.each do |id,verbum|
      csv.write(id.to_s + ";" + verbum.uebersetzungen.join(";") + ";" + verbum.treffsicherheit.to_s + "\n")
    end
  end
end


class Vocabulum
  attr_reader :verbi
  # attr_accessor :treffsicherheiten

  def initialize(id, linguae, verbi, treffsicherheiten)
    @id = id
    @linguae = linguae
    @verbi = verbi
    @treffsicherheiten = treffsicherheiten
  end

  def zeige_treffer(ausgangssprachennr,uebersetzungssprachennr)
    treffer = @treffsicherheiten[ausgangssprachennr]
    return treffer
  end

  def schreibe_treffer(ausgangssprachennr,uebersetzungssprachennr,treffer)
    @treffsicherheiten[ausgangssprachennr] = treffer
  end

end


class Corpus
  attr_reader :linguae

  def initialize(verbi,linguae)
    @verbi = verbi
    @linguae = linguae

    # @lima.dateiinhalt.each do |elementi|
    #   @alleworte[elementi[0].to_i] = Verbum.new(elementi[0].to_i, elementi[1..-2], elementi[-1].to_i)
    # end
  end

  def extrahiere_uebungscorpus(ausgangssprachennr, uebersetzungssprachennr, wortanzahl=5)
    # wortanzahl > @verbi.size ? umfang = @verbi.size : umfang = wortanzahl
    # tsliste = []
    # min = 10000000000 #Achtung: spaeter moegliche Fehlerquelle 
    # max = 0
    # @verbi.each do |id, verbum|
    #   min = verbum.treffsicherheit if verbum.treffsicherheit < min
    #   max = verbum.treffsicherheit if verbum.treffsicherheit > max
    #   tsliste[verbum.treffsicherheit] ? tsliste[verbum.treffsicherheit] << id : tsliste[verbum.treffsicherheit] = [id]
    # end
    # aus der tsliste nun von unten = ganz schwer 20%, aus der Mitte = noch nicht sicher 60% und von oben = sicher 20% nehmen
    # vorerst:
    zu_trainierende_worte = @verbi
    uebungscorpus = Corpus.new(zu_trainierende_worte, @linguae)
    return uebungscorpus
  end

  def aktualisiere(uebungscorpus)
    uebungscorpus.each do |id,verbum|
      @verbi[id] = verbum
    end
  end

end


class Trainer
  attr_reader :uebungscorpus

  def initialize(uebungscorpus,ausgangssprachennr,uebersetzungssprachennr,mixed=false)
    @uebungscorpus = uebungscorpus
    @ausgangssprachennr = ausgangssprachennr
    @uebersetzungssprachennr = uebersetzungssprachennr
    @mixed = mixed

  end

  def training(durchlaeufe)
    durchlaeufe.times do
      id = rand(1..@uebungscorpus.size)
      aenigma(id)
    end

    return treffer
  end

  def aenigma(id)
    verbum = @uebungscorpus[id]
    frage = verbum.uebersetzungen[@ausgangssprachennr]
    antwort = verbum.uebersetzungen[@uebersetzungssprachennr]
    system('clear')
    print "Die Übersetzung für #{frage} lautet: "
    versuch = gets
    treffer = verbum.zeige_treffer(ausgangssprachennr,uebersetzungssprachennr)
    if versuch.chomp! == antwort
      puts "Jawoll"
      treffer += 1
      sleep 1
      return 1
    else
      puts "Nope :-( Die Antwort lautet ::::  #{antwort}  ::::"
      treffer -= 1 if treffer > 0
      sleep 2
      return 0
    end
    verbum.schreibe_treffer(ausgangssprachennr,uebersetzungssprachennr,treffer)
  end

end

puts "Dann wollen wir mal..."
uebungsdatei = Lima.new("verbi.csv")
corpus = Corpus.new(uebungsdatei.vocabuli, uebungsdatei.linguae)
puts "Ich habe folgende Sprachen zur Auswahl:"
puts corpus.linguae.join(",")
print "Welche Sprache soll Deine Ausgangssprache sein [de] : "
ausgangssprache = gets
ausgangssprache.chomp!
if ausgangssprache == ""
  ausgangssprachennr = corpus.linguae.index("de")
else
  while not corpus.linguae.include?(ausgangssprache)
    puts "#{ausgangssprache} habe ich nicht im Angebot. Bitte wähle zwischen"
    puts corpus.linguae.join(",")
    print "Welche Sprache soll Deine Ausgangssprache sein [de] : "
    ausgangssprache = gets
    ausgangssprache.chomp!
  end
  ausgangssprachennr = corpus.linguae.index(ausgangssprache)
end

print "OK, und welche der o.g. Sprachen möchtest Du üben? : "

uebersetzungssprache = gets
uebersetzungssprache.chomp!
while not corpus.linguae.include?(uebersetzungssprache)
  puts "#{uebersetzungssprache} habe ich nicht im Angebot. Bitte wähle zwischen"
  puts corpus.linguae.join(",")
  print "Welche Sprache möchtest Du lernen? : "
  uebersetzungssprache = gets
  uebersetzungssprache.chomp!
end
uebersetzungssprachennr = corpus.linguae.index(uebersetzungssprache)

uebungscorpus = corpus.extrahiere_uebungscorpus(ausgangssprachennr, uebersetzungssprachennr, 5)
trainer = Trainer.new(uebungscorpus, ausgangssprachennr, uebersetzungssprachennr)
treffer = trainer.training(3)
corpus.aktualisiere(trainer.uebungscorpus)
system('clear')
puts "Du hattest #{treffer} Treffer."