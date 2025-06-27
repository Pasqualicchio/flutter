from pathlib import Path

# Percorso del file HTML da generare
template_path = Path("templates/upload-advanced-ui.html")
template_path.parent.mkdir(parents=True, exist_ok=True)

# Contenuto aggiornato del file
html_content = """<!DOCTYPE html>
<html lang="it">
<head>
  <meta charset="UTF-8">
  <title>📤 Upload Avanzato</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <style>
    .preview-img { max-height: 150px; margin: 10px 0; display: block; }
    #toastSuccess {
      position: fixed;
      top: 20px;
      right: 20px;
      z-index: 1050;
    }
  </style>
</head>
<body class="container py-4">
  <h2 class="mb-4">📤 Upload Avanzato con Anteprima</h2>

  <!-- ✅ TOAST SUCCESSO -->
  <div id="toastSuccess" class="toast align-items-center text-bg-success border-0" role="alert" aria-live="assertive" aria-atomic="true">
    <div class="d-flex">
      <div class="toast-body">
        ✅ File caricato con successo!
      </div>
      <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast" aria-label="Chiudi"></button>
    </div>
  </div>

  <form id="uploadForm">
    <div class="mb-3">
      <label class="form-label">Macro Categoria</label>
      <select class="form-select" name="macro" id="macroSelect" required>
        <option>00 = Rilievi</option>
        <option>01 = Produzione</option>
        <option>02 = As build</option>
        <option>03 = Spedizione</option>
        <option>04 = Montaggio</option>
        <option>05 = Funzionamento</option>
        <option>06 = Inconvenienti</option>
        <option>07 = Magazzino</option>
        <option>08 = Laboratorio</option>
      </select>
    </div>

    <div class="mb-3" id="lineaGroup" style="display: none;">
      <label class="form-label">Linea</label>
      <select class="form-select" name="linea" id="lineaSelect">
        <option>FILM</option>
        <option>PET</option>
      </select>
    </div>

    <div class="mb-3">
      <label class="form-label">Commessa</label>
      <input class="form-control" name="commessa" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Matricola</label>
      <input class="form-control" name="matricola" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Item</label>
      <input class="form-control" name="item" required>
    </div>
    <div class="mb-3">
      <label class="form-label">Immagine</label>
      <input type="file" class="form-control" accept="image/*" name="image" id="imageInput" required>
      <img id="preview" class="preview-img" style="display:none;" />
    </div>
    <button type="submit" class="btn btn-success">📤 Carica Immagine</button>
  </form>

  <!-- Bootstrap JS -->
  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>

  <script>
    const form = document.getElementById("uploadForm");

    document.getElementById("macroSelect").addEventListener("change", function () {
      document.getElementById("lineaGroup").style.display =
        this.value.includes("05 = Funzionamento") ? "block" : "none";
    });

    document.getElementById("imageInput").addEventListener("change", function () {
      const file = this.files[0];
      if (file) {
        const reader = new FileReader();
        reader.onload = function (e) {
          const preview = document.getElementById("preview");
          preview.src = e.target.result;
          preview.style.display = "block";
        };
        reader.readAsDataURL(file);
      }
    });

    form.addEventListener("submit", function (e) {
      e.preventDefault();
      const formData = new FormData(form);
      const file = document.getElementById("imageInput").files[0];
      if (!file) return alert("⚠️ Nessun file selezionato");

      fetch("/upload", {
        method: "POST",
        body: formData
      })
        .then(res => res.json())
        .then(data => {
          if (data.status === "success") {
            showSuccessToast("✅ File caricato con successo!");
            form.reset();
            document.getElementById("preview").style.display = "none";
          } else {
            alert("❌ Errore: " + data.message);
          }
        })
        .catch(err => alert("❌ Errore di rete: " + err));
    });

    function showSuccessToast(message) {
      const toast = document.getElementById("toastSuccess");
      toast.querySelector(".toast-body").innerText = message;
      new bootstrap.Toast(toast).show();
    }
  </script>
</body>
</html>"""

# Scrive il file nella directory
template_path.write_text(html_content, encoding="utf-8")

str(template_path)
