#!/bin/sh

# Check input parameters
id="$1"
output_file="$2"

if [[ -z "$email" ]]; then
  echo "Usage: $0 <UM ID number> [output_file]"
  echo "Example: $0 a100000 msgFilterRules.dat"
  exit 1
fi

trash_folder="imap://$id%40uminho.pt@outlook.office365.com/Trash"

# Base filters for spam and unwanted messages
subject_filters=(
  "alug"   
  "propag" 
  "vend"   
  "anúnc"  
  "arrend" 
  "ofert"  
  "descont"
  "promoç" 
  "spam"   
  "arrend" 
)

correspondent_filters=(
  "sec@ecum.uminho.pt"
  "gci@gci.uminho.pt"
  "comunica@direito.uminho.pt"
  "cecs@ics.uminho.pt"
  "divulgacao@usapi.uminho.pt"
  "ciec@ie.uminho.pt"
  "torgal@civil.uminho.pt"
  "gpe@gpe.uminho.pt"
  "confucio@confucio.uminho.pt"
  "musica@elach.uminho.pt"
  "sociedade@aaum.pt"
  "configuracoes_cics@ics.uminho.pt"
  "sec-dout-ce@ie.uminho.pt"
  "news@lab2pt.uminho.pt"
  "comunica@sas.uminho.pt"
  "pg49890@alunos.uminho.pt"
  "a100442@alunos.uminho.pt"
  "gci@eeg.uminho.pt"
  "a101416@alunos.uminho.pt"
  "pg51677@alunos.uminho.pt"
  "a92568@alunos.uminho.pt"
  "a107038@alunos.uminho.pt"
  "mjit@dsi.uminho.pt"
  "bolsas@ecum.uminho.pt"
  "sec-bandeira@reitoria.uminho.pt"
  "arqus@elach.uminho.pt"
  "recrutamento@uminho.pt"
  "recrutamento@sas.uminho.pt"
  "usdb@usdb.uminho.pt"
  "mgpe@eng.uminho.pt"
  "pg48379@alunos.uminho.pt"
  "sici-le@le.uminho.pt"
  "start@tecminho.uminho.pt"
  "bpb@bpb.uminho.pt"
  "pg53175@alunos.uminho.pt"
  "a103234@alunos.uminho.pt"
  "pg49914@alunos.uminho.pt"
  "id10753@alunos.uminho.pt"
  "pg49173@alunos.uminho.pt"
  "a103492@alunos.uminho.pt"
  "mrocha@di.uminho.pt"
  "nipe@eeg.uminho.pt"
  "mvila@psi.uminho.pt"
  "divulgacao@eng.uminho.pt"
  "reitor@reitoria.uminho.pt"
  "info-cehum@elach.uminho.pt"
)

# Start writing to the output file
echo 'version="9"' > "$output_file"
echo 'logging="no"' >> "$output_file"
echo 'name="UM Lixo"' >> "$output_file"
echo 'enabled="yes"' >> "$output_file"
echo 'type="17"' >> "$output_file"
echo 'action="Move to folder"' >> "$output_file"
echo "actionValue=\"${trash_folder}\"" >> "$output_file"

# Add filter conditions for subject
echo -n 'condition="' >> "$output_file"
for filter in "${subject_filters[@]}"; do
  echo -n "OR (subject,contains,${filter}) " >> "$output_file"
done

# Add filter conditions for correspondent (body)
for filter in "${correspondent_filters[@]}"; do
  echo -n "OR (from,contains,${filter}) " >> "$output_file"
done

echo '"' >> "$output_file"

echo "File $output_file generated successfully!"

