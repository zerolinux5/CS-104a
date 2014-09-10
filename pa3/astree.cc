
#include <assert.h>
#include <inttypes.h>
#include <stdarg.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iomanip>
#include "astree.h"
#include "stringset.h"
#include "lyutils.h"

astree* new_astree (int symbol, int filenr, int linenr,
                    int offset, const char* lexinfo) {
   astree* tree = new astree();
   tree->symbol = symbol;
   tree->filenr = filenr;
   tree->linenr = linenr;
   tree->offset = offset;
   tree->lexinfo = intern_stringset (lexinfo);
   DEBUGF ('f', "astree %p->{%d:%d.%d: %s: \"%s\"}\n",
           tree, tree->filenr, tree->linenr, tree->offset,
           get_yytname (tree->symbol), tree->lexinfo->c_str());
   return tree;
}

astree* adopt1 (astree* root, astree* child) {
   root->children.push_back (child);
   DEBUGF ('a', "%p (%s) adopting %p (%s)\n",
           root, root->lexinfo->c_str(),
           child, child->lexinfo->c_str());
   return root;
}

astree* adopt2 (astree* root, astree* left, astree* right) {
   adopt1 (root, left);
   adopt1 (root, right);
   return root;
}

astree* adopt3 (astree* root, astree* left, astree* middle, astree* right) {
   adopt2(root, left, middle);
   adopt1(root, right);
   return root;
}

astree* adopt4 (astree* root, astree* left, astree* leftmiddle, astree* rightmiddle, astree* right){
   adopt2(root, left, leftmiddle);
   adopt2(root, rightmiddle, right);
   return root;
}

astree* adopt5 (astree* root, astree* left, astree* left2, 
		astree* mid, astree* right2, astree* right){
   adopt3(root, left, left2, mid);
   adopt2(root, right2, right);
   return root;
}

astree* adopt1sym (astree* root, astree* child, int symbol) {
   root = adopt1 (root, child);
   root->symbol = symbol;
   return root;
}


static void dump_node (FILE* outfile, astree* node) {
   fprintf (outfile, " %ld %ld.%03ld  %4d %-15s (%s)",
            node->filenr,  node->linenr, node->offset,
            node->symbol, get_yytname (node->symbol),
            node->lexinfo->c_str());
   bool need_space = false;
   for (size_t child = 0; child < node->children.size();
        ++child) {
      if (need_space) fprintf (outfile, " ");
      need_space = true;
      fprintf (outfile, "%p", node->children.at(child));
   }
}

static void dump_astree_rec (FILE* outfile, astree* root,
                             int depth) {
   if (root == NULL) return;
   dump_node (outfile, root);
   fprintf (outfile, "\n");
   for (size_t child = 0; child < root->children.size();
        ++child) {
      dump_astree_rec (outfile, root->children[child],
                       depth + 1);
   }
}

void dump_astree (FILE* outfile, astree* root) {
   dump_astree_rec (outfile, root, 0);
   fflush (NULL);
}

static void dump_node2 (FILE* outfile, astree* node, int depth) {
  //Here I am indenting for the depth of each node
   for(int i = 0; i < 3*depth; i++){
      fprintf(outfile, " ");
   }
   //I am showing the values in each astree with this algorithm
   if (string(get_yytname(node->symbol)).find("TOK_ROOT") != string::npos){
      fprintf (outfile, " %s",node->lexinfo->c_str()); 
   } else if (string(get_yytname(node->symbol)).find("+")!= string::npos || 
              string(get_yytname(node->symbol)).find("-")!= string::npos ||
              string(get_yytname(node->symbol)).find("*")!= string::npos ||
              string(get_yytname(node->symbol)).find("/")!= string::npos ||
              string(get_yytname(node->symbol)).find("%")!= string::npos ||
              string(get_yytname(node->symbol)).find("=")!= string::npos){
      fprintf (outfile, " %-15s %s", get_yytname (node->symbol),
      node->lexinfo->c_str());
   } else if (string(get_yytname(node->symbol)).find("TOK") != string::npos){
      fprintf (outfile, " %-15s %s", get_yytname (node->symbol),
      node->lexinfo->c_str());
   } else {
      fprintf (outfile, " %s",
            node->lexinfo->c_str()); 
   }
   bool need_space = false;
   for (size_t child = 0; child < node->children.size();
        ++child) {
      if (need_space) fprintf (outfile, " ");
      need_space = true;
      fprintf (outfile, "%p", node->children.at(child));
   }
}

static void dump_astree_rec2 (FILE* outfile, astree* root,
                             int depth) {
   if (root == NULL) return;
   dump_node2 (outfile, root, depth);
   fprintf (outfile, "\n");
   for (size_t child = 0; child < root->children.size();
        ++child) {
      dump_astree_rec2 (outfile, root->children[child],
                       depth + 1);
   }
}

void dump_astree2 (FILE* outfile, astree* root) {
   dump_astree_rec2 (outfile, root, 0);
   fflush (NULL);
}

void yyprint (FILE* outfile, unsigned short toknum,
              astree* yyvaluep) {
   if (is_defined_token (toknum)) {
      dump_node (outfile, yyvaluep);
   }else {
      fprintf (outfile, "%s(%d)\n",
               get_yytname (toknum), toknum);
   }
   fflush (NULL);
}


void free_ast (astree* root) {
   while (not root->children.empty()) {
      astree* child = root->children.back();
      root->children.pop_back();
      free_ast (child);
   }
   DEBUGF ('f', "free [%p]-> %d:%d.%d: %s: \"%s\")\n",
           root, root->filenr, root->linenr, root->offset,
           get_yytname (root->symbol), root->lexinfo->c_str());
   delete root;
}

void free_ast2 (astree* tree1, astree* tree2) {
   free_ast (tree1);
   free_ast (tree2);
}
