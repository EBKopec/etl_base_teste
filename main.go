package main

import (
	"database/sql"
	"fmt"
	"io/ioutil"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"text/template"

	// "mime/multipart"

	"github.com/gorilla/mux"
	_ "github.com/lib/pq"
)

const (
	host     = "database"
	port     = 5432
	user     = "postgres"
	password = "nw2020"
	dbname   = "nw_base_teste"
)

func checkErr(err error) {
	if err != nil {
		panic(err)
	}
}

var templates = template.Must(template.ParseFiles("index.html"))

// Display the named template
func display(w http.ResponseWriter, page string, data interface{}) {
	templates.ExecuteTemplate(w, page+".html", data)
}

func uploadHandler(w http.ResponseWriter, r *http.Request) {

	switch r.Method {
	case "GET":
		display(w, "index", nil)
	case "POST":
		upload(w, r)
	}
}

func fileExists(path string) bool {
	_, err := os.Stat(path)
	return !os.IsNotExist(err)
}

func uploadFile(fileUploaded string) {
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s "+
		"password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)
	db, err := sql.Open("postgres", psqlInfo)
	checkErr(err)
	defer db.Close()

	file := fmt.Sprintf("/mnt/file/%s", filepath.Base(fileUploaded))

	sql := fmt.Sprintf(`COPY fileUploaded(dados) FROM '%s';`, file)
	// fmt.Sprintf("Mydirs %s", sql)
	sqlStatement, err := db.Exec(sql)
	if err != nil {
		fmt.Println(sqlStatement, err)
	}
	// Show the rows affected
	affected, err := sqlStatement.RowsAffected()
	checkErr(err)

	fmt.Println("Registros Inseridos: ", affected)
}

func upload(w http.ResponseWriter, r *http.Request) {

	fmt.Println("Rota de Upload de arquivo alcançada")
	// Parse our multipart form, 10 << 20 specifies a maximum
	// upload of 10 MB files.
	r.ParseMultipartForm(10 << 20)
	// FormFile returns the first file for the given key `myFile`
	// it also returns the FileHeader so we can get the Filename,
	// the Header and the size of the file
	file, handler, err := r.FormFile("myFile")
	if err != nil {
		fmt.Println("Erro ao Recuperar o arquivo")
		fmt.Println(err)
		return
	}
	defer file.Close()

	fmt.Printf("Uploaded File: %+v\n", handler.Filename)
	fmt.Printf("File Size: %+v\n", handler.Size)
	fmt.Printf("MIME Header: %+v\n", handler.Header)

	myDir, err := os.Getwd()
	if err != nil {
		fmt.Println(err)
	}

	tempFile, err := ioutil.TempFile(fmt.Sprintf("%s", myDir), fmt.Sprintf("*-%s", handler.Filename))
	if err != nil {
		fmt.Println(err)
	}

	fileBytes, err := ioutil.ReadAll(file)
	if err != nil {
		fmt.Println(err)
	}
	tempFile.Write(fileBytes)

	uploadFile(fmt.Sprintf("%s", tempFile.Name()))
	defer tempFile.Close()
	// uploadFile(file)
	// return that we have successfully uploaded our file!
	fmt.Fprintf(w, "Arquivo %s Carregado com Sucesso!\n", handler.Filename)

}

func homePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Bem vindo Everton!")
	fmt.Println("EndPoint hit: HomePage")
}

func handleRequests() {
	myRouter := mux.NewRouter().StrictSlash(true)
	myRouter.HandleFunc("/", homePage)
	myRouter.HandleFunc("/upload", uploadHandler)
	log.Fatal(http.ListenAndServe(":10000", myRouter))
}

func main() {
	fmt.Println("Rest API v2.0 - Mux Routers")
	handleRequests()
}
