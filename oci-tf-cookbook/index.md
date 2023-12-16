---
layout: collection
title: OCI Terraform Cookbook
series: oci-tf-cookbook
description: Awesome tips| tricks and techniques for using Terraform with OCI.
thumbnail: assets/cookbook.jpg
author: tim-clegg
tags: [open-source| terraform| iac| devops]
---
{% img aligncenter assets/cookbook.jpg 400 400 "OCI Terraform Cookbook" "OCI Terraform Cookbook" %}
*(Photo by [Ron Lach](https://www.pexels.com/@ron-lach?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels) from [Pexels](https://www.pexels.com/photo/food-wood-dawn-coffee-8188946/?utm_content=attributionCopyText&utm_medium=referral&utm_source=pexels))*

We hope that you find these solutions of benefit as you build OCI solutions using Terraform.  These are organized in a problem/solution format, with all of the problems being in the index (below).  Happy coding!

Ps. These are designed to work with Oracle Cloud Infrastructure (OCI).  If you don't have an OCI account get an OCI Always-Free account [here]({{site.urls.always_free }})!

{%- assign alphabet = "a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,t,u,v,w,x,y,z" | split: "," -%}
{%- assign letters_with_content = "" -%}

{%- for letter in alphabet -%}
  {%- for page in site.pages -%}
    {%- if page.path contains 'collections/tutorials/oci-tf-cookbook'" -%}
      {%- for name in page.solution_names -%}
        {%- assign first_letter = name | slice: 0 | downcase -%}
        {%- if first_letter == letter -%}
          {%- unless letters_with_content contains letter -%}
            {%- if letters_with_content != "" -%}
              {%- assign letters_with_content = letters_with_content | append: "," | append: letter -%}
            {%- else -%}
              {%- assign letters_with_content = letter -%}
            {%- endif -%}
          {%- endunless -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endfor -%}
{%- endfor -%}

{%- assign letters_to_render = letters_with_content | split: "," %}

<div id="nav">
<h1>Navigation</h1>
{%- for letter in letters_to_render -%}
<a href="#{{letter}}">{{letter}}</a>&nbsp;
{% endfor %}
</div>

# Solution Index
{%- for letter in letters_to_render %}
<div id="{{letter}}">
<h2>{{ letter }}  &nbsp;<a href="#nav">top ^</a></h2>
  
  {%- assign solution_names = "" -%}
  {%- for page in site.pages -%}
    {%- if page.path contains 'collections/tutorials/oci-tf-cookbook'" -%}
      {%- for name in page.solution_names -%}
        {%- assign fltr = name | slice: 0 | downcase -%}
        {%- if fltr == letter -%}
          {%- if solution_names != "" -%}
            {%- assign solution_names = solution_names | append: "," | append: name -%}
          {%- else -%}
            {%- assign solution_names = name -%}
          {%- endif -%}
        {%- endif -%}
      {%- endfor -%}
    {%- endif -%}
  {%- endfor -%}
  {%- assign solution_names = solution_names | split: "," | sort_natural -%}
  
  {%- for name in solution_names -%}
    {%- for page in site.pages -%}
      {%- if page.path contains 'collections/tutorials/oci-tf-cookbook'" -%}
        {%- for page_name in page.solution_names -%}
          {%- if name == page_name -%}
  <a href="{{ page.url }}">{{ name }}</a><br />
          {%- endif -%}
        {%- endfor -%}
      {%- endif -%}
    {%- endfor -%}
  {%- endfor -%}
  
</div>
{%- endfor -%}
