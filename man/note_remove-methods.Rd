% Generated by roxygen2 (4.0.1): do not edit by hand
\docType{methods}
\name{note_remove}
\alias{note_remove}
\alias{note_remove,git_note-method}
\title{Remove the note for an object}
\usage{
note_remove(note, author = default_signature(note@repo),
  committer = default_signature(note@repo))

\S4method{note_remove}{git_note}(note, author = default_signature(note@repo),
  committer = default_signature(note@repo))
}
\arguments{
\item{note}{The note to remove}

\item{author}{Signature of the notes commit author.}

\item{committer}{Signature of the notes commit committer.}
}
\value{
invisible NULL
}
\description{
Remove the note for an object
}
\keyword{methods}
