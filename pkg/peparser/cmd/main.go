package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strings"

	peparser "github.com/saferwall/saferwall/pkg/peparser"
)

func parse(filename string) {
	log.Printf("Processing filename %s", filename)
	pe, err := peparser.Open(filename)
	if err != nil {
		log.Printf("Error while opening file: %s, reason: %s", filename, err)
		return
	}

	err = pe.Parse()
	if err != nil {
		log.Printf("Error while parsing file: %s, reason: %s", filename, err)
		return
	}

	for _, imp := range pe.Imports {
		log.Println(imp.Name)
		log.Println("=============================================")
		for _, function := range imp.Functions {
			hint := fmt.Sprintf("%X", function.Hint)
			offset := fmt.Sprintf("%X", function.Offset)

			log.Printf("%s, hint: 0x%s, thunk: 0x%s", function.Name, hint, offset)
		}
		log.Println("=============================================")

	}
	log.Println("==========================================================================================")

}

func isDirectory(path string) bool {
	fileInfo, err := os.Stat(path)
	if err != nil {
		return false
	}
	return fileInfo.IsDir()
}

func main() {
	var searchDir string

	if len(os.Args) > 1 {
		searchDir = os.Args[1]

	} else {
		currentDir, err := os.Getwd()
		if err != nil {
			log.Fatal(err)
		}

		searchDir = currentDir + string(os.PathSeparator) + "bin"
	}

	log.Printf("Processing directory %s", searchDir)

	fileList := []string{}
	filepath.Walk(searchDir, func(path string, f os.FileInfo, err error) error {
		if !isDirectory(path) && (strings.HasSuffix(path, ".dll") || strings.HasSuffix(path, ".exe")) {
			fileList = append(fileList, path)
		}
		return nil
	})

	for _, file := range fileList {
		parse(file)
	}
}